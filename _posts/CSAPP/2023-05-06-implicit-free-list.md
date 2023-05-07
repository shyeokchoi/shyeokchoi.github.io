---
title:  "[CSAPP] MALLOC LAB 풀이 (implicit free list)"

categories:
  - CSAPP
tags:
  - [CS, C, csapp]

toc: true
toc_sticky: true
 
date: 2023-05-06
last_modified_at: 2023-05-06
published: true
---
**CS:APP LAB 자료 링크: <http://csapp.cs.cmu.edu/3e/labs.html>**  
**혹시 잘못된 내용이 있다면 메일이나 댓글로 알려주시면 정말 감사하겠습니다**  
   
# Implicit Free List
먼저 가장 간단한 구현인 implicit free list 형태의 구현부터 살펴보고 이 코드를 베이스로 리팩토링 해가겠습니다.
## Macros
``` c
/* pointer which points to middle of the prologue block */
static char * heap_listp;

/* single word (4) or double word (8) alignment */
#define ALIGNMENT 8
#define WSIZE 4
#define DSIZE 8
#define CHUNKSIZE (1<<12)

/* minimum block size : space for header, footer and for alignment*/
#define MINIMUM_BLK_SIZE (ALIGN(DSIZE + 1)) // == 16

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
#define NEXT_BLKP(bp) (FTRP(bp) + DSIZE)
#define PREV_BLKP(bp) (((char *) (bp)) - GET_SIZE(((char *)bp) - DSIZE))

#define SIZE_T_SIZE (ALIGN(sizeof(size_t)))
#define MAX(x, y) (x) > (y) ? x : y
```
앞으로 이 게시물 내에서 계속 사용될 매크로 들입니다. 포인터 연산에 있어서 실수하지 않도록 매크로 형태로 정의했습니다.  
## Helper Functions
```c
/*
 * extend_heap - Extend heap by 'words'. Coalesce if previous block was free.
 * return bp of the extended heap.
 */ 
static void* extend_heap(size_t words) 
{
    char* bp;

    int aligned_words = words % 2 == 0 ? words : words + 1;

    int extend_size = aligned_words * WSIZE;

    if ((bp = (char *) mem_sbrk(extend_size)) == (char *) -1) {
        return NULL;
    }

    PUT_W(bp - WSIZE, PACK(extend_size, 0));
    PUT_W(FTRP(bp), PACK(extend_size, 0));
    PUT_W(FTRP(bp) + WSIZE, 1);

    return coalesce(bp);
}

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

        PUT_W(HDRP(bp), PACK(size_after_coalesce, 0));
        PUT_W(FTRP(bp), PACK(size_after_coalesce, 0));
    }

    if (!is_prev_allocated) {
        size_after_coalesce += GET_SIZE(HDRP(prev_blkp));

        PUT_W(HDRP(prev_blkp), PACK(size_after_coalesce, 0));
        PUT_W(FTRP(bp), PACK(size_after_coalesce, 0));

        return (void *) prev_blkp;
    }

    return (void *) bp;
}

static void *allocate(void *bp, size_t blk_size)
{
    size_t curr_blk_size = GET_SIZE(HDRP(bp));

    if (curr_blk_size - blk_size >= MINIMUM_BLK_SIZE) { /* splitting possible */
        PUT_W(HDRP(bp), PACK(blk_size, 1));
        PUT_W(FTRP(bp), PACK(blk_size, 1));
        char *next_blkp = NEXT_BLKP(bp);
        PUT_W(HDRP(next_blkp), PACK(curr_blk_size - blk_size, 0));
        PUT_W(FTRP(next_blkp), PACK(curr_blk_size - blk_size, 0));
    } else {
        PUT_W(HDRP(bp), PACK(curr_blk_size, 1));
        PUT_W(FTRP(bp), PACK(curr_blk_size, 1));
    }

    
    return bp;
}
```
`extend_heap` 함수는 현재 할당받은 힙이 충분하지 않을 경우 `mem_sbrk` 함수를 호출해 힙 공간을 더 할당받습니다. 원래의 `sbrk` 함수는 힙이 아니라 data segment를 더 받지만, 이 과제에서는 힙의 끝을 연장하는 함수입니다. 자세한 내용은 저자들이 제공하는 `memlib.c` 파일의 함수를 읽어보시면 됩니다.  
`coalesce` 함수는 뒤에 등장할 `free` 함수의 끝에 호출되는 함수로, 지금 해제되는 블록의 이전, 이후 블록이 해제되어 있는 블록이라면 병합해줍니다. 이를 통해 external fragmentation을 줄일 수 있습니다.  
`allocate` 함수는 splitting이 가능하다면 splitting 후에 특정 블록의 allocate bit를 1로 설정해줍니다. 만약 splitting이 불가능하다면 바로 해당 블록을 allocate 된 상태로 표시합니다. splitting을 해줌으로써 internal fragmentation을 예방할 수 있습니다.  

## mm_init
```c
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

    if (extend_heap(CHUNKSIZE/WSIZE) == NULL) {
        return -1;
    }

    return 0;
}
```
`heap_listp` 는 prologue block의 중간을 가리키는 전역변수입니다.  
`mm_init`은 prologue block과 epilogue block을 세팅한 후 `extend_heap`을 호출해 최초의 힙을 세팅합니다.  
## mm_malloc
```c
void *mm_malloc(size_t size)
{
    if (size == 0) {
        return NULL;
    }

    int adjusted_size = ALIGN(size + DSIZE); /* necessary space considering alignment, header, footer */

    /*
     * handle: start from bp of the first block.
     * iterate until: it reaches the epilogue block OR find fitting space
     */
    char *handle;
    for (handle = heap_listp + DSIZE; GET_SIZE(HDRP(handle)) > 0; handle = NEXT_BLKP(handle)) {
        if (!GET_ISALLOCATED(HDRP(handle)) && GET_SIZE(HDRP(handle)) >= adjusted_size) {
            return allocate(handle, adjusted_size);
        }
    }

    int extend_size = MAX(adjusted_size, CHUNKSIZE);

    if ((handle = extend_heap(extend_size/WSIZE)) == NULL) {
        return NULL;
    }

    return allocate(handle, adjusted_size);
}
```
`mm_malloc` 함수는 일단 사용자가 요청한 size에 대해 footer, header를 고려해 DSIZE( == double word size)를 더해주고 alignment condition을 맞춰줍니다.  
이후 implicit free list를 순회하며 충분한 공간이 보인다면 바로 할당해주고, 끝까지 그런 공간을 찾지 못하면 `extend_heap`을 호출하여 충분한 힙을 할당받습니다.  
## mm_free
```c
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
이 `mm_free`에 주어지는 parameter인 ptr는 매 블록의 시작지점 (header의 주소)가 아니라 블록의 payload가 시작되는 지점입니다. 이 점에 유의해서 ptr를 기준으로 allocated bit만 0으로 바꿔주고 coalesce해주면 됩니다.    
## mm_realloc
```c
void *mm_realloc(void *ptr, size_t size)
{
    void *oldptr = ptr;
    void *newptr;
    size_t copySize;
    
    newptr = mm_malloc(size);
    if (newptr == NULL)
      return NULL;
    copySize = GET_SIZE(HDRP(oldptr));
    if (size < copySize)
      copySize = size;
    memcpy(newptr, oldptr, copySize);
    mm_free(oldptr);
    return newptr;
}
```
일단은 `mm_realloc`은 `mm_malloc`의 wrapper function 식으로 구현했습니다.  
뒤쪽에 이어지는 free block이 있는지 확인하지 않고 그냥 사용자가 요청한 크기의 공간을 새로 할당받아서 거기다가 기존의 내용물을 옮겨적는 식입니다.  
후에 이어지는 게시물에서 리팩토링할 예정입니다.  
# 결론
스켈레톤에 제공된 `mdriver.c`를 실행해보면 다음과 같은 결과가 나옵니다.  
![화면 캡처 2023-02-28 164115](https://user-images.githubusercontent.com/106307725/221786323-d12b1063-2088-44e6-abeb-41eb1c7ae988.png)  
보시다시피 이렇게만 구현하면 작동 자체는 valid하지만 최적화에 있어서 59점이라는 낮은 점수를 받게됩니다 ㅜㅜ  
Implicit free list가 아닌 다른 방법을 찾아야 하겠습니다. Explicit free list, Segregated free list 모두 구현해볼 예정입니다.    
바로 다음 포스팅으로 이어집니다!  
