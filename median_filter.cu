#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <iostream>
#include <cstdlib>
#include <cstring>
#include <stdio.h>

using namespace cv;
using namespace std;



// Values for MxN matrix
#define M 562
#define N 800


__global__ void median_filter(int *a, int *b, int *c)
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


int main( int argc, char** argv )
{
	
	size_t bytes = M*N*sizeof(int);

	int A[M][N];


	int C[M][N];

	

	int B[5][5] =
    	{
		{0,1,1,1,0},
		{1,2,2,2,1},
		{1,2,4,2,1},
		{1,2,2,2,1},
		{0,1,1,1,0}
    	};

	//cout<<"printing data\n";
    if( argc != 2)
    {
     cout <<" Usage: display_image ImageToLoadAndDisplay" << endl;
     return -1;
    }

    Mat image;
    image = imread(argv[1]);   // Read the file

    if(! image.data )                              // Check for invalid input
    {
        cout <<  "Could not open or find the image" << std::endl ;
        return -1;
    }

	
	
	for(int j=0;j<image.rows;j++) 
	{
	  for (int i=0;i<image.cols;i++)
	  {
	       A[j][i] = (int)image.at<uchar>(j,i);
		//count++;
	  }
		//cout<<"\n";
	}

	//CUDA function call here
	

	int *d_A, *d_B, *d_C;
	cudaMalloc(&d_A, bytes);
	cudaMalloc(&d_B, bytes);
	cudaMalloc(&d_C, bytes);

	
	for(int i=0; i<M; i++)
	{
		for(int j=0; j<N; j++)
		{
			C[i][j] = 1;
		}
	}



	cudaMemcpy(d_A, A, bytes, cudaMemcpyHostToDevice);
	cudaMemcpy(d_B, B, bytes, cudaMemcpyHostToDevice);

	
	dim3 threads_per_block( 16, 32, 1 );
	dim3 blocks_in_grid( ceil( (float(N) / threads_per_block.x) ), ceil( float(M) / threads_per_block.y ), 1 );

	// Launch kernel
	median_filter<<< blocks_in_grid, threads_per_block >>>(d_A, d_B, d_C);

	

 
	// Copy data from device array d_C to host array C
	cudaMemcpy(C, d_C, bytes, cudaMemcpyDeviceToHost);

	// Verify results
	printf("Displaying data\n\n");
	

	for(int j=0;j<M;j++) 
	{
	  for (int i=0;i<N;i++)
	  {
	       image.at<uchar>(j,i) = C[j][i];
		//count++;
	  }
		//cout<<"\n";
	}

	// Free GPU memory
	cudaFree(d_A);
	cudaFree(d_B);
	cudaFree(d_C);


	
	

    namedWindow( "Display window", WINDOW_AUTOSIZE );
    imshow( "Display window", image );                  
   
    waitKey(0);                                       


	
	

    return 0;
}
