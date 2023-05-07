---
title:  "[CSAPP] MALLOC LAB 풀이 (explicit free list)"

categories:
  - CSAPP
tags:
  - [CS, C, csapp]

toc: true
toc_sticky: true
 
date: 2023-05-07
last_modified_at: 2023-05-07
published: true
---
**CS:APP LAB 자료 링크: <http://csapp.cs.cmu.edu/3e/labs.html>**  
**혹시 잘못된 내용이 있다면 메일이나 댓글로 알려주시면 정말 감사하겠습니다**  
   
전체 코드 git repository: https://github.com/qqq1130/SNU_System_Programming_2023_Spring/tree/master/malloclab/handout
# Block들의 구조
Free block의 경우 HEADER, PREV block pointer, NEXT block pointer, FOOTER 로, 총 4개의 word로 구성되어있습니다.  
따라서 최소한의 크기는 16바이트가 됩니다. (해당 과제에서는 하나의 word size를 4바이트로 둡니다.)  
Allocated block의 경우 HEADER, FOOTER로 2개의 word를 필요로 하지만, free block이 되는 경우도 고려해야 하기 때문에 마찬가지로 최소 크기를 16바이트로 잡습니다.  
# Explicit Free List
## 구현
```c
/* single word (4) or double word (8) alignment */
#define ALIGNMENT 8
#define WSIZE 4
#define DSIZE 8
#define CHUNKSIZE (1<<12)

/* minimum block size : space for header, footer, prev ptr, next ptr (for freed block) and for alignment*/
#define MINIMUM_BLK_SIZE 16

/* Pack a size and allocated bit into a word */
#define PACK(size, alloc) ((size) | (alloc))

/* rounds up to the nearest multiple of ALIGNMENT */
#define ALIGN(size) (((size) + (ALIGNMENT-1)) & ~0x7)

/* read WSIZE bytes from pointer p */
#define GET_W(p) (*((unsigned int *) (p)))

/* write WSIZE bytes of value 'val' to pointer p */
#define PUT_W(p, val) (*((unsigned int *) (p)) = (val)) 

/* getting size of the block from header or footer at address p */
#define GET_SIZE(p) (GET_W(p) & ~0x7)

/* getting allocated bit from header or footer at address p */
#define GET_ISALLOCATED(p) (GET_W(p) & 0x1)

/* given block pointer bp, compute address of its header and footer */
#define HDRP(bp) (((char *) (bp)) - WSIZE)
#define FTRP(bp) (((char *) (bp)) + GET_SIZE(HDRP(bp)) - DSIZE)

/* given block pointer bp, return next / prev block pointer */
#define NEXT_BLKP(bp) ((char *)(bp) + GET_SIZE((char *)(bp) - WSIZE))
#define PREV_BLKP(bp) ((char *)(bp) - GET_SIZE((char *)(bp) - DSIZE))

#define SIZE_T_SIZE (ALIGN(sizeof(size_t)))
#define MAX(x, y) (x) > (y) ? x : y
#define MIN(x, y) (x) < (y) ? x : y

/* number of segregated list */
#define NUM_SEG_LIST 10

/* get prev, next for free block given bp */
#define GET_PREV_PTR(bp) (*((unsigned int *) bp))
#define GET_NEXT_PTR(bp) (*(((unsigned int *) bp) + 1))

/* set prev, next for free block given bp */
#define SET_PREV_PTR(bp, addr) (GET_PREV_PTR(bp) = (unsigned int) (addr))
#define SET_NEXT_PTR(bp, addr) (GET_NEXT_PTR(bp) = (unsigned int) (addr))

/* standard of blk size. when to start from head, when to start from tail? */
#define STANDARD 2048
```
사용되는 매크로들입니다.  
```c
/* pointer which points to middle of the prologue block */
static char *heap_listp;
/* segregated list to manage free blocks */
static void *free_list_head;
static void *free_list_tail;
```
prologue block의 가운데를 가리키는 `heap_listp` static 변수와 explicit free list의 head를 가리킬 `free_list_head` 변수, explicit free list의 tail을 가리킬 `free_list_tail` 변수를 선언해주었습니다.  
```c
/*
 * extend_heap - Extend heap by 'words'. Coalesce if previous block was free.
 * return bp of the extended heap.
 */ 
static void* extend_heap(size_t words) 
{
    char* bp;

    int aligned_words = words % 2 == 0 ? words : words + 1;

    size_t extend_size = aligned_words * WSIZE;

    if ((bp = (char *) mem_sbrk(extend_size)) == (char *) -1) {
        return NULL;
    }

    PUT_W(HDRP(bp), PACK(extend_size, 0));
    PUT_W(FTRP(bp), PACK(extend_size, 0));
    PUT_W(FTRP(bp) + WSIZE, PACK(0, 1)); /* set the epilogue block */

    return coalesce(bp);
}
```
Heap space가 부족할 때 새로운 heap을 받아오는 함수입니다. 
```c
/* coalesce with next or prev block. Remove coalesced block from the freelist. Return bp after coalesce */
static void* coalesce(void *bp) 
{
    char* next_blkp = NEXT_BLKP(bp);
    char* prev_blkp = PREV_BLKP(bp);
    size_t size = GET_SIZE(HDRP(bp));
    size_t size_after_coalesce = size;

    int is_next_allocated = GET_ISALLOCATED(HDRP(next_blkp));
    int is_prev_allocated = GET_ISALLOCATED(HDRP(prev_blkp));

    if (!is_next_allocated) { /* if continuihng block is free => coalesce */
        size_after_coalesce += GET_SIZE(HDRP(next_blkp));
        
        remove_node(next_blkp);
        PUT_W(HDRP(bp), PACK(size_after_coalesce, 0));
        PUT_W(FTRP(bp), PACK(size_after_coalesce, 0));
    }

    if (!is_prev_allocated) { /* if preceding block is free => coalesce*/
        size_after_coalesce += GET_SIZE(HDRP(prev_blkp));

        remove_node(prev_blkp);
        PUT_W(HDRP(prev_blkp), PACK(size_after_coalesce, 0));
        PUT_W(FTRP(bp), PACK(size_after_coalesce, 0));

        bp = (void *) prev_blkp;
    }

    insert_node(bp, GET_SIZE(HDRP(bp))); /* insert the coalesced block */

    return (void *) bp;
}
```
연속된 free block이 있을 때 external fragmentation을 방지하기 위해 합쳐주는 함수입니다.  
먼저 연속된 block들이 이미 할당되어 있는지 확인하고, 할당되어 있지 않다면 차례대로 현재 블록과 합쳐줍니다.  
매번 새로운 block을 free할때마다 호출되는 함수입니다.  
```c
/* mark given block (bp) as allocated. split if possible. 
 * add the splitted blk to the freelist, remove allocated blk from the freelist.
 */
static void *allocate(void *bp, size_t blk_size)
{
    remove_node(bp);

    size_t curr_blk_size = GET_SIZE(HDRP(bp));

    if (curr_blk_size - blk_size > MINIMUM_BLK_SIZE) {  /* split possible */
        /* if the block is big enough: put it at the back of the block 
         * so that when new heap space is allocated,
         * we can keep small allocated blocks in the front of the heap space
         * and big allocated blocks in the back of the heap space.
        */
        if (blk_size >= 100) { 
            PUT_W(HDRP(bp), PACK(curr_blk_size - blk_size, 0));
            PUT_W(FTRP(bp), PACK(curr_blk_size - blk_size, 0));
            char *next_blkp = NEXT_BLKP(bp);
            PUT_W(HDRP(next_blkp), PACK(blk_size, 1));
            PUT_W(FTRP(next_blkp), PACK(blk_size, 1));
            insert_node(bp, curr_blk_size - blk_size);
            return next_blkp;
        } else {
            PUT_W(HDRP(bp), PACK(blk_size, 1));
            PUT_W(FTRP(bp), PACK(blk_size, 1));
            char *next_blkp = NEXT_BLKP(bp);
            PUT_W(HDRP(next_blkp), PACK(curr_blk_size - blk_size, 0));
            PUT_W(FTRP(next_blkp), PACK(curr_blk_size - blk_size, 0));
            insert_node(next_blkp, curr_blk_size - blk_size);
        }
    } else { /* too small to split*/
        PUT_W(HDRP(bp), PACK(curr_blk_size, 1));
        PUT_W(FTRP(bp), PACK(curr_blk_size, 1));
    }

    return bp;
}
```
주어진 free block을 가리키는 포인터 `bp`가 parameter로 주어집니다.  
`blk_size`는 `malloc`을 통해 할당해달라고 요청된 block의 사이즈입니다.  
이 두 정보를 가지고, 현재 선택된 free block의 splitting이 가능한지를 판단한 후, splitting이 가능하다면 나눠줘야합니다.  
이때 만약 `blk_size`가 크다면 free block의 뒤쪽을 할당해주고, `blk_size`가 작다면 free block의 앞쪽을 할당해줘서 최대한 크기가 비슷한 블록끼리 모여있도록 유도했습니다.  
제가 한 구현이 explicit free list에서 free block들을 크기순으로 링크드리스트로 관리하기에 caching 등을 고려하면 이렇게 구현하는 것이 throughput에 유리할 것이라고 판단했습니다.  
링크드 리스트 상에서 추상화된 연속성이 아닌, 링크드 리스트상에서 연속된 block 들이라면 실제 메모리공간에서도 (최대한.. 어느정도는) 연속되게 구현한다면 caching의 이득이 있지 않을까 하고 판단했습니다.   
```c
/* add freed block at bp with size blk_size to appropriate position of the free list */
static void insert_node(void *bp, size_t blk_size) 
{
    void *prev = NULL;
    void *next = NULL;

    if (blk_size >= STANDARD) { /* big block: search from the tail of the list */
        prev = free_list_tail;

        while (prev && (blk_size < GET_SIZE(HDRP(prev)))) {
            next = prev;
            prev = (void *)GET_PREV_PTR(prev);
        }
    } else { /* small block: search from the head of the list */
        next = free_list_head;

        while (next && (blk_size > GET_SIZE(HDRP(next)))) {
            prev = next;
            next = (void *)GET_NEXT_PTR(next);
        }
    }
        
    if (prev) {
        if (next) {
            SET_NEXT_PTR(bp, next);
            SET_PREV_PTR(bp, prev);
            SET_NEXT_PTR(prev, bp);
            SET_PREV_PTR(next, bp);
        } else {
            /* bp is biggest. add to the tail of the free list */
            SET_NEXT_PTR(bp, NULL);
            SET_PREV_PTR(bp, prev);
            SET_NEXT_PTR(prev, bp);
            free_list_tail = bp;
        }
    } else {
        if (next) {
            /* bp is smallest. add at the head of the free list */
            SET_PREV_PTR(bp, NULL);
            SET_NEXT_PTR(bp, next);
            SET_PREV_PTR(next, bp);
            free_list_head = bp;
        } else {
            /* when the free list was empty */
            free_list_tail = bp;
            free_list_head = bp;
            SET_NEXT_PTR(bp, NULL);
            SET_PREV_PTR(bp, NULL);
        }
    }
}
```
링크드 리스트에 free block을 삽입하는 로직입니다.  
링크드 리스트(explicit free list)의 head 쪽으로 갈수록 작은 free block들을, tail 쪽으로 갈수록 큰 free block들을 정렬된 순서로 유지합니다.  
주어진 `STANDARD` 보다 현재 삽입하고자 하는 free block의 크기가 크다면 뒤쪽에서부터 자리를 찾고, 반대의 경우 앞쪽에서부터 자리를 찾는 식으로 최적화했습니다. 이렇게 하면 로직은 first fit 이지만, 어느정도는 best fit에 근접한 구현을 할 수 있습니다.    
```c
/* select free block of size blk_size to allocate */
static void *find_fitting_blk(size_t blk_size) 
{
    char* bp;

    if (blk_size >= STANDARD) {
        /* search from back of the free list */
        bp = free_list_tail;
        while(bp && (blk_size > GET_SIZE(HDRP(bp)))) {
            bp = (char *)GET_PREV_PTR(bp);
        }   
    } else {
        /* search from head of the free list */
        bp = free_list_head;
        while (bp && (blk_size > GET_SIZE(HDRP(bp)))) {
            bp = (char *)GET_NEXT_PTR(bp);
        }
    }

    
    if (!bp) { //no matching block found 
        int extend_size = MAX(blk_size, CHUNKSIZE);
        return extend_heap(extend_size/WSIZE);
    } else { //found
        return bp;
    }
}
```
메모리 할당을 요청받았을 때 free list를 순회하며 충분한 크기의 free block을 찾아서 반환하는 함수입니다. 만약 찾는데 실패하면 더 많은 힙 공간을 할당받아 반환합니다.  
`insert_node`와 마찬가지로, `STANDARD` 이상의 크기는 뒤쪽에서부터, `STANDARD` 이하의 크기는 앞쪽에서부터 free list를 순회하며 `blk_size`보다 큰 free block을 찾습니다.  
```c
/*
removing node from linked list (free list)
*/
static void remove_node(void *bp) 
{
    if (GET_PREV_PTR(bp)) {
		if (GET_NEXT_PTR(bp)) { /* there exist prev and next */
            SET_NEXT_PTR(GET_PREV_PTR(bp), GET_NEXT_PTR(bp));
            SET_PREV_PTR(GET_NEXT_PTR(bp), GET_PREV_PTR(bp));
		} else { /* there exist prev, no next => bp is the last block of the free list */
            SET_NEXT_PTR(GET_PREV_PTR(bp), NULL);
			free_list_tail = (void *) GET_PREV_PTR(bp);
		}
	} else { 
		if (GET_NEXT_PTR(bp)) { /* no prev, exist next => bp is the first block of the free list */
            SET_PREV_PTR(GET_NEXT_PTR(bp), NULL);
            free_list_head = (void *) GET_NEXT_PTR(bp);
        } else { /* the only block in the free list removed */
			free_list_tail = NULL;
            free_list_head = NULL;
        }
	}
}
```
링크드 리스트(free list)에서 노드를 삭제하는 로직입니다.  
```c
/* 
 * mm_init - initialize the malloc package.
 */
int mm_init(void)
{
    if ((heap_listp = (char *) mem_sbrk(4 * WSIZE)) == (char *) (-1)) {
        return -1;
    }

    PUT_W(heap_listp, 0);
    PUT_W(heap_listp + WSIZE, PACK(DSIZE, 1));
    PUT_W(heap_listp + 2 * WSIZE, PACK(DSIZE, 1));
    PUT_W(heap_listp + 3 * WSIZE, PACK(0, 1));
    heap_listp += DSIZE;

    /* initialize free_list */
    free_list_head = NULL;
    free_list_tail = NULL;

    void *bp; 

    if ((bp = extend_heap(CHUNKSIZE/WSIZE)) == NULL) {
        return -1;
    }

    return 0;
}
```
새로운 heap 공간을 할당받습니다. prologue block, epilogue block을 설정해주고, free list를 초기화합니다.    
```c
/* 
 * mm_malloc - Allocate a block by incrementing the brk pointer.
 *     Always allocate a block whose size is a multiple of the alignment.
 */
void *mm_malloc(size_t size)
{
    if (size == 0) {
        return NULL;
    }

    int adjusted_size = ALIGN(size + DSIZE); /* necessary space considering alignment, header and footer */

    void *bp;

    if ((bp = find_fitting_blk(adjusted_size)) == NULL) {
        return NULL;
    }

    return allocate(bp, adjusted_size);
}
```
C standard library로 치면 `malloc`의 역할을 하는 함수입니다.  
주어진 크기에 대해 적절한 크기의 free block을 explicit free list에서 찾아내고, 해당 블록에 `allocate` 함수를 호출합니다.  
앞서 서술했듯이, `allocate` 함수는 주어진 블록을 (가능하다면) splitting 한 후 HEADER와 FOOTER에 해당 블록이 할당되었다고 표시해주는 역할을 합니다.   
```c
/*
 * mm_free - Freeing a block. 
 * Gets bp as an input and frees the block 
 */
void mm_free(void *ptr)
{
    char* hdrp = HDRP(ptr);
    char* ftrp = FTRP(ptr);
    size_t curr_block_size = GET_SIZE(hdrp);

    PUT_W(hdrp, PACK(curr_block_size, 0));
    PUT_W(ftrp, PACK(curr_block_size, 0));
    coalesce(ptr);
}
```
C standard library로 치면 `free`의 역할을 하는 함수입니다.  
HEADER와 FOOTER의 값을 바꿔서 해당 블록이 할당 해제되었다고 표시해줍니다.  
이후 `coalesce` 함수를 호출하는데, 연속된 free block들이 있을 경우 external fragmentation을 예방하기 위해 서로 합쳐준 후 explicit free list에 추가해주는 역할을 합니다.  
```c
/*
 * mm_realloc
 */
void *mm_realloc(void *ptr, size_t size)
{
    void *newptr = ptr;
	size_t new_blk_size;
	size_t extend_size;
	int remaining_size;

	if (size == 0) {
		return NULL;
    }

    /* for alignment conditions */
	if (size <= DSIZE) {
        new_blk_size = 2*DSIZE;
    } else {
		new_blk_size = ALIGN(size + DSIZE);
    }

	if (GET_SIZE(HDRP(ptr)) < new_blk_size) {
        remaining_size = GET_SIZE(HDRP(ptr)) + GET_SIZE(HDRP(NEXT_BLKP(ptr))) - new_blk_size;

		if (!GET_ISALLOCATED(HDRP(NEXT_BLKP(ptr)))) { /* if next block free */
			if (remaining_size >= 0) {
                remove_node(NEXT_BLKP(ptr));
                PUT_W(HDRP(ptr), PACK(new_blk_size + remaining_size, 1));
                PUT_W(FTRP(ptr), PACK(new_blk_size + remaining_size, 1));
            }
		} else if (GET_SIZE(HDRP(ptr)) == 0 && (remaining_size < 0)) {
            /* extend heap */
            extend_size = MAX(-remaining_size, CHUNKSIZE);
            if (extend_heap(extend_size/WSIZE) == NULL) {
                return NULL;
            }

            remaining_size += extend_size; /* now, new_blk_size + remaining_size == (initial size of the block) + (extended size) */

            PUT_W(HDRP(ptr), PACK(new_blk_size + remaining_size, 1)); 
            PUT_W(FTRP(ptr), PACK(new_blk_size + remaining_size, 1)); 
        } else {
			newptr = mm_malloc(new_blk_size - DSIZE); /* -DSIZE for header and footer */
			memcpy(newptr, ptr, MIN(size, new_blk_size));
			mm_free(ptr);
		}
	}

    return newptr;
}
```
C standard library로 치면 `realloc`의 역할을 하는 함수입니다.  
사용자가 현재 block 사이즈보다 더 큰 block을 요청한다면 일단 먼저 바로 다음 block이 할당 해제되어 있는지 확인합니다.   
만약 다음 block이 해제된 상태이고, 그 block까지 합쳤을 때 사용자가 요청한 공간을 할당해줄 수 있다면 그렇게 두 block을 병합한 후 반환해줍니다.  
만약 바로 이어지는 block이 epilogue block 이라면, 사용자의 요청에 부합할 만큼 충분한 크기의 힙을 새로 요청한 후에 반환합니다.  
어떤 방법도 불가능하다면, `mm_malloc`으로 새로운 block을 할당받고 그곳으로 원래의 데이터를 옮깁니다.  
이후 원래의 block을 할당 해제해줍니다.  
```c
#ifdef DEBUG
static int mm_check()
{
	void *bp;

	for (bp = free_list_head; bp; bp = (void *) GET_NEXT_PTR(bp)) {
        if (GET_ISALLOCATED(HDRP(bp))) { /* check if every block in the free list is free */
            printf("free block allocated at %u\n", (unsigned int) bp);
            return 0;
        }

        /* visualize blocks in the free list */
        printf("[ curr: %u, size: %d, prev: %u, next: %u ] ", (unsigned int) bp, GET_SIZE(HDRP(bp)), GET_PREV_PTR(bp), GET_NEXT_PTR(bp));
    }
    printf("\n");

	/* Check if every free blocks are coalesced properly */
	for (bp = free_list_head; bp; bp = (void *) GET_NEXT_PTR(bp)) {
		if ((void *)GET_PREV_PTR(bp) == PREV_BLKP(bp)) {
            printf("coalesce failed\n");
            return 0;
        }
    }

	return 1;
}
#endif
```
디버깅에 사용한 함수입니다.  
explicit free list에 있는 block들이 실제로 free 된 상태가 맞는지, 또 모든 연속된 free block들이 coalesce 되어 있는지 확인합니다.  
또, free list에 있는 block들을 시각화해줍니다.  
# 결과물
![explicit free list](https://user-images.githubusercontent.com/106307725/235311196-71d88de6-03e0-4233-97f4-985491c89bc2.png)  
# 어려웠던 점
반복되는 Segfault 오류를 디버깅하는 것이 가장 어려웠습니다.  
곳곳에서 `printf` 함수로 시각화를 해가며 해결했습니다.  
또, 논리적으로 Segfault 오류가 일어날 수 있는 부분들의 후보군들(예를 들어, 링크드 리스트에 노드를 넣고 빼는 과정)을 정하고 조금씩 디버깅하며 후보군을 좁혀가는 방식으로 해결했습니다.  
복잡한 포인터 연산을 고민하는 것에서도 어려움을 겪었습니다.  
이 부분은 깊이 고민하여 설계한 MACRO의 사용으로 해결할 수 있었습니다.   

# 새롭게 배운 점
막연하게만 느껴지던 메모리 할당의 원리에 대해서 깊게 고민하고 실습할 수 있었습니다.  
또한 테스트코드의 중요성을 깨달을 수 있었습니다.  
좋은 테스트코드를 작성하는 것은 번거롭고 복잡할 수 있지만, 결국 디버깅과 개발 속도에 큰 도움이 됨을 체감할 수 있었습니다.  
