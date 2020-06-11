#include <stdio.h>

// Macro for checking errors in CUDA API calls
#define cudaErrorCheck(call)                                                              \
do{                                                                                       \
    cudaError_t cuErr = call;                                                             \
    if(cudaSuccess != cuErr){                                                             \
      printf("CUDA Error - %s:%d: '%s'\n", __FILE__, __LINE__, cudaGetErrorString(cuErr));\
      exit(0);                                                                            \
    }                                                                                     \
}while(0)

// Values for MxN matrix
#define M 10
#define N 10

// Kernel
__global__ void add_matrices(int *a, int *b, int *c)
{
	int column = blockDim.x * blockIdx.x + threadIdx.x;
	int row    = blockDim.y * blockIdx.y + threadIdx.y;

	int array[32];
	int count = 0;

	if (row < M && column < N)
	{
		int thread_id = row * N + column;
		//c[thread_id] = a[thread_id] + b[thread_id];
		//c[thread_id] = a[thread_id] + 1;

		if(row > 1 && column > 1 && row < M - 2 && column < N - 2)
		{
			for(int i = 0 ; i < 25; i++)
			{
				for (int j = 0 ; j < b[i]; j++)
				{
					if (i < 5)
						array[count] = a[thread_id - (2*N) - 2 + i];

					else if (i < 10)
						array[count] = a[thread_id - N - 2 + i - 5];

					else if (i < 15)
						array[count] = a[thread_id - 2 + i - 10];

					else if (i < 20)
						array[count] = a[thread_id + N - 2 + i - 15];

					else if (i < 25)
						array[count] = a[thread_id + (2*N) - 2 + i - 20];
						
					count++;
				}
			}

			
			
			


			for (int i = 0 ; i < 32; i++)
			{
				for (int j = 0 ; j < 32; j++)
				{
					if (array[j] > array [j + 1])
					{
						int temp = array[j];
						array[j] = array[j+1];
						array[j+1] = temp;
					}
				}
			}	



		
		if(row == 2 && column == 3)
		{
			for (int j = 0 ; j < 32; j++)
					{
						printf("%d ", array[j]);
							
					}


		}		




			c[thread_id] = array[31/2];

		}
		//int num = a[thread_id];
		
		

	}
}

// Main program
int main()
{
	// Number of bytes to allocate for MxN matrix
	size_t bytes = M*N*sizeof(int);

	// Allocate memory for arrays A, B, and C on host
	int A[M][N]=
    	{
		{249,255,252,255,235,0,255,255,255,243},
		{244,255,241,255,255,253,252,0,255,233},
		{255,255,242,248,249,239,248,3,237,255},
		{245,244,254,255,255,255,250,255,255,238},
		{255,241,255,242,255,236,255,0,254,251},
		{253,255,244,255,250,255,245,251,252,255},
		{233,255,248,239,255,243,255,251,4,0},
		{255,240,252,252,255,252,238,255,252,255},
		{255,248,253,247,255,252,255,247,253,255},
		{250,0,251,255,246,247,240,255,246,244}
    	};
	
		


	int C[M][N];

	

	int B[5][5] =
    	{
		{0,1,1,1,0},
		{1,2,2,2,1},
		{1,2,4,2,1},
		{1,2,2,2,1},
		{0,1,1,1,0}
    	};

	for(int i=0; i<5; i++)
	{
		for(int j=0; j<5; j++)
		{
			printf("%d", B[i][j]);
		}
		printf("\n");
	}

	

	// Allocate memory for arrays d_A, d_B, and d_C on device
	int *d_A, *d_B, *d_C;
	cudaErrorCheck( cudaMalloc(&d_A, bytes) );
	cudaErrorCheck( cudaMalloc(&d_B, bytes) );
	cudaErrorCheck( cudaMalloc(&d_C, bytes) );

	// Initialize host arrays A and B
	for(int i=0; i<M; i++)
	{
		for(int j=0; j<N; j++)
		{
			C[i][j] = 1;
		}
	}

	

	// Copy data from host arrays A and B to device arrays d_A and d_B
	cudaErrorCheck( cudaMemcpy(d_A, A, bytes, cudaMemcpyHostToDevice) );
	cudaErrorCheck( cudaMemcpy(d_B, B, bytes, cudaMemcpyHostToDevice) );

	// Set execution configuration parameters
	// 		threads_per_block: number of CUDA threads per grid block
	//		blocks_in_grid   : number of blocks in grid
	//		(These are c structs with 3 member variables x, y, x)
	dim3 threads_per_block( 16, 16, 1 );
	dim3 blocks_in_grid( ceil( float(N) / threads_per_block.x ), ceil( float(M) / threads_per_block.y ), 1 );

	// Launch kernel
	add_matrices<<< blocks_in_grid, threads_per_block >>>(d_A, d_B, d_C);

	// Check for errors in kernel launch (e.g. invalid execution configuration paramters)
  cudaError_t cuErrSync  = cudaGetLastError();

	// Check for errors on the GPU after control is returned to CPU
  cudaError_t cuErrAsync = cudaDeviceSynchronize();

  if (cuErrSync != cudaSuccess) 
	{ printf("CUDA Error - %s:%d: '%s'\n", __FILE__, __LINE__, cudaGetErrorString(cuErrSync)); exit(0); }

  if (cuErrAsync != cudaSuccess) 
	{ printf("CUDA Error - %s:%d: '%s'\n", __FILE__, __LINE__, cudaGetErrorString(cuErrAsync)); exit(0); }

	// Copy data from device array d_C to host array C
	cudaErrorCheck( cudaMemcpy(C, d_C, bytes, cudaMemcpyDeviceToHost) );

	// Verify results
	printf("Displaying data\n\n");
	

	for(int i=0; i<M; i++)
	{
		for(int j=0; j<N; j++)
		{
			printf("%d\t", C[i][j]);
		}
		printf("\n");
	}

	// Free GPU memory
	cudaErrorCheck( cudaFree(d_A) );
	cudaErrorCheck( cudaFree(d_B) );
	cudaErrorCheck( cudaFree(d_C) );

  printf("\n--------------------------------\n");
  printf("__SUCCESS__\n");
  printf("--------------------------------\n");
  printf("M                         = %d\n", M);
	printf("N                         = %d\n", N);
  printf("Threads Per Block (x-dim) = %d\n", threads_per_block.x);
  printf("Threads Per Block (y-dim) = %d\n", threads_per_block.y);
  printf("Blocks In Grid (x-dim)    = %d\n", blocks_in_grid.x);
	printf("Blocks In Grid (y-dim)    = %d\n", blocks_in_grid.y);
  printf("--------------------------------\n\n");

	return 0;
}
