# Median_Filter_Cuda

This program was created as a term project for the course GP-GPU. 

It uses the library OpenCV to retrive and store images. The images are stored in a 2D array. Which is then passed to
the CUDA kernel. Each thread works on a pixel retrieving the neighbour pixel values and uses the image kernel (5x5) to repeat intensities and picks a median to create 
a filtered image which is sent back and displayed to the user



To run the program, the user needs cuda toolkit and Opencv. Just run the script build_and_run.sh with the image path/name to compile and run the program.

