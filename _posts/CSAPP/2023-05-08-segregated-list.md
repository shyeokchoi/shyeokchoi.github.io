---
title:  "[CSAPP] MALLOC LAB 풀이 (segregated free list)"

categories:
  - CSAPP
tags:
  - [CS, C, csapp]

toc: true
toc_sticky: true
 
date: 2023-05-08
last_modified_at: 2023-05-08
published: true
---
**CS:APP LAB 자료 링크: <http://csapp.cs.cmu.edu/3e/labs.html>**  
**혹시 잘못된 내용이 있다면 메일이나 댓글로 알려주시면 정말 감사하겠습니다**  

# Block들의 구조
Free block의 경우 HEADER, NEXT block pointer, PREV block pointer, FOOTER 로, 총 4개의 word로 구성되어있습니다.  
따라서 최소한의 크기는 16바이트가 됩니다. (해당 과제에서는 하나의 word size를 4바이트로 둡니다.)  
Allocated block의 경우 HEADER, FOOTER로 2개의 word를 필요로 하지만, free block이 되는 경우도 고려해야 하기 때문에 마찬가지로 최소 크기를 16바이트로 잡습니다.  

# Segregated Free List
10개의 free list를 관리합니다.  
각 free list는 특정 크기의 free block들을 가지고 있습니다.  
첫번째 list는 ~ 2^5 까지,  
두번째 list는 ~ 2^6 까지,  
세번째 list는 ~ 2^7 까지,   
...  
식입니다.  
## 구현
```c
// ***********************************************************
// MACROs
// ***********************************************************

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

/* set prev, next for free block given bp */

#define SET_NEXT_PTR(bp, addr) (*((unsigned int *) bp) = (unsigned int) (addr))
#define SET_PREV_PTR(bp, addr) (*(((unsigned int *) bp) + 1) = (unsigned int) (addr))

/* get prev, next for free block given bp */
#define GET_NEXT_PTR(bp) ((void *)(*((unsigned int *) bp)))
#define GET_PREV_PTR(bp) ((void *) (*(((unsigned int *) bp) + 1)))

/* heap consistency checker */
#define MM_CHECK mm_check()
```
```c
/* pointer which points to middle of the prologue block */
static char *heap_listp;
/* segregated list to manage free blocks */
static void *seg_list[NUM_SEG_LIST];
```
`seg_list`가 앞으로 사용할 segregated list 입니다.
```c
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
/* coalesce with next or prev block. Remove coalesced block from the seglist. Return bp after coalesce */
static void* coalesce(void *bp) 
{
    char* next_blkp = NEXT_BLKP(bp);
    char* prev_blkp = PREV_BLKP(bp);
    size_t size = GET_SIZE(HDRP(bp));
    size_t size_after_coalesce = size;

    int is_next_allocated = GET_ISALLOCATED(HDRP(next_blkp));
    int is_prev_allocated = GET_ISALLOCATED(HDRP(prev_blkp));

    if (!is_next_allocated) {
        size_after_coalesce += GET_SIZE(HDRP(next_blkp));
        
        remove_node(next_blkp);
        PUT_W(HDRP(bp), PACK(size_after_coalesce, 0));
        PUT_W(FTRP(bp), PACK(size_after_coalesce, 0));
    }

    if (!is_prev_allocated) {
        size_after_coalesce += GET_SIZE(HDRP(prev_blkp));

        remove_node(prev_blkp);
        PUT_W(HDRP(prev_blkp), PACK(size_after_coalesce, 0));
        PUT_W(FTRP(bp), PACK(size_after_coalesce, 0));

        bp = (void *) prev_blkp;
    }

    insert_node(bp, GET_SIZE(HDRP(bp)));

    return (void *) bp;
}
```
연속된 free block이 있을 때 external fragmentation을 방지하기 위해 합쳐주는 함수입니다.  
먼저 연속된 block들이 이미 할당되어 있는지 확인하고, 할당되어 있지 않다면 차례대로 현재 블록과 합쳐줍니다.  
매번 새로운 block을 free할때마다 호출되는 함수입니다.  
```c
/* mark given block (bp) as allocated. split if possible. 
 * add the splitted blk to the seglist, remove allocated blk from the seglist.
 */
static void *allocate(void *bp, size_t blk_size)
{
    size_t curr_blk_size = GET_SIZE(HDRP(bp));

    if (curr_blk_size - blk_size >= MINIMUM_BLK_SIZE) {
        PUT_W(HDRP(bp), PACK(blk_size, 1));
        PUT_W(FTRP(bp), PACK(blk_size, 1));
        char *next_blkp = NEXT_BLKP(bp);
        PUT_W(HDRP(next_blkp), PACK(curr_blk_size - blk_size, 0));
        PUT_W(FTRP(next_blkp), PACK(curr_blk_size - blk_size, 0));
        insert_node(next_blkp, curr_blk_size - blk_size);
    } else {
        PUT_W(HDRP(bp), PACK(curr_blk_size, 1));
        PUT_W(FTRP(bp), PACK(curr_blk_size, 1));
    }

    return bp;
}
```
주어진 free block을 가리키는 포인터 `bp`가 parameter로 주어집니다.  
`blk_size`는 `malloc`을 통해 할당해달라고 요청된 block의 사이즈입니다.  
이 두 정보를 가지고, 현재 선택된 free block의 splitting이 가능한지를 판단한 후, splitting이 가능하다면 나눠줘야합니다.  
```c
/* add freed block at bp with size blk_size to appropriate seglist */
static void insert_node(void *bp, size_t blk_size) 
{
    int list = 0;
    size_t size = blk_size;

    size >>= 5;

    for (; list < NUM_SEG_LIST - 1; ++list) {
        if (size <= 1) {
            break;
        }

        size >>= 1;
    }

    void **seglist_start = &seg_list[list];
    void *new_node = bp;
    void *next_node = seg_list[list];

    SET_PREV_PTR(new_node, seglist_start);
    SET_NEXT_PTR(new_node, next_node);
    SET_NEXT_PTR(seglist_start, new_node); 

    if (next_node) {
        SET_PREV_PTR(next_node, new_node);
    }
    return;
}
```
Segregated free list에 free block을 삽입하는 로직입니다.  
`size >>= 5` 를 먼저 해주는건 어차피 모든 블록의 최소 크기가 16이기 때문입니다.  
이후 bit shifting을 통해 적절한 segregated free list 위치를 찾아주고, 리스트의 가장 앞에 넣어줍니다.  
```c
/* select free block of size blk_size to allocate */
static void *find_fitting_blk(size_t blk_size) 
{
    int list = 0;
    size_t size = blk_size;
    
    size >>= 5; /* minimum size of a free block is 16. */

    while ((list < NUM_SEG_LIST - 1) && (size > 1)) {
        size >>= 1;
        ++list;
    }

    while (list < NUM_SEG_LIST) {
        void *curr = seg_list[list];

        while (curr) {
            if (GET_SIZE(HDRP(curr)) > blk_size) {
                return curr;
            }

            curr = GET_NEXT_PTR(curr);
        }

        ++list;
    }

    /* reaching here == block not found */
    int extend_size = MAX(blk_size, CHUNKSIZE);
    return extend_heap(extend_size/WSIZE);
}
```
`insert_node` 함수와 비슷한 로직으로 순회할 segregated list를 먼저 정합니다.  
이후 segregated list를 순회하며 할당받을 수 있는 충분한 크기의 block을 찾습니다.  
만약 골랐던 segregated list에서 충분한 크기의 block을 찾지 못하면 그 다음 크기의 segregated list를 찾아봅니다.  
모든 segregated list를 순회했음에도 충분한 크기의 block을 찾지 못했다면, 새로운 힙 공간을 요청합니다.  
```c
static void remove_node(void *bp) 
{
    void *prev_node = GET_PREV_PTR(bp);
    void *next_node = GET_NEXT_PTR(bp);

    SET_NEXT_PTR(prev_node, next_node);

    if (next_node) {
        SET_PREV_PTR(next_node, prev_node);
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

    for (int i = 0; i < NUM_SEG_LIST; ++i) {
        seg_list[i] = NULL;
    }

    PUT_W(heap_listp, 0);
    PUT_W(heap_listp + WSIZE, PACK(DSIZE, 1));
    PUT_W(heap_listp + 2 * WSIZE, PACK(DSIZE, 1));
    PUT_W(heap_listp + 3 * WSIZE, PACK(0, 1));
    heap_listp += DSIZE;

    void *bp; 

    if ((bp = extend_heap(CHUNKSIZE/WSIZE)) == NULL) {
        return -1;
    }

    return 0;
}
```
새로운 heap 공간을 할당받습니다. prologue block, epilogue block을 설정해주고, segregated free list를 초기화합니다.    
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

    remove_node(bp);
    return allocate(bp, adjusted_size);
}
```
C standard library로 치면 `malloc`의 역할을 하는 함수입니다.  
주어진 크기에 대해 적절한 크기의 free block을 segregated free list에서 찾아내고, 해당 블록에 `allocate` 함수를 호출합니다.  
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
이후 `coalesce` 함수를 호출하는데, 연속된 free block들이 있을 경우 external fragmentation을 예방하기 위해 서로 합쳐준 후 segregated free list에 추가해주는 역할을 합니다.  
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
		} else if (GET_SIZE(HDRP(ptr)) == 0) {
            if (remaining_size < 0) { /* extend heap */
				extend_size = MAX(-remaining_size, CHUNKSIZE);
				if (extend_heap(extend_size/WSIZE) == NULL) {
                    return NULL;
                }
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
static void mm_check() {
    printf("===========================\n");
    printf("[Log] mm_check start\n");
    // iterate through the seglist, print out the blocks in each of it
    for (int list = 0; list < NUM_SEG_LIST; ++list) {
        printf("[List #%d] %p : ", list, &seg_list[list]);

        if (!seg_list[list]) {
            printf("empty list\n");
            continue;
        }
        void *curr = seg_list[list];
        
        while(curr) {
            printf("[curr_address: %p, curr_allocated: %d, blk_size: %d, prev: %p, next: %p]", curr, GET_ISALLOCATED(HDRP(curr)), GET_SIZE(HDRP(curr)), GET_PREV_PTR(curr), GET_NEXT_PTR(curr));
            curr = GET_NEXT_PTR(curr);
            if (curr) {
                printf(" -> ");
            } else {
                printf("\n");
            }
        }
    }
    printf("===========================\n");
}
```
디버깅에 사용한 함수입니다.  
segregated free list마다 내부에 있는 block들을 시각화해서 보여줍니다.
# 결과물 
![화면 캡처 2023-04-30 011425](https://user-images.githubusercontent.com/106307725/235312630-9bea2d18-e326-4bd1-b02f-d1fe260aa051.png)<br>
 
오히려 이전 게시물에서 다룬 explicit free list의 성능이 더 뛰어난 모습입니다.
throughput은 둘 다 만점을 받았지만, segregated free list는 메모리의 활용 성능이 떨어지는 모습입니다.  
아마 throughput 자체는 segregated list가 높을 것 같은데 만점이 40점이라 그런게 아닐까.. 싶습니다.  
