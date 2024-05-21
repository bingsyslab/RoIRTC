#include <stdint.h>
#include <iostream> // temp

using namespace std;

texture<float, 2, cudaReadModeElementType> tex_ref; // texure reference must be a global variable

__device__ float CUDAradians(float degrees) {return 0.01745329252 * degrees;}

__global__ void CUDARotateKernel(void) {}

__global__ void CUDATransformKernel(float* cuda_transformed_data,
                                    int width,
                                    int height,
                                    float y,
                                    float p,
                                    float r,
                                    float ratio,
                                    int n) {
  int index = threadIdx.x + blockIdx.x * blockDim.x;
  if (index < n) {
    // float u = (index % width) / __int2float_rn(width);
    float u = __fdividef(__int2float_rn(index % width), __int2float_rn(width));
    // float v = (index / width) / __int2float_rn(height);
    float v = __fdividef(__int2float_rn(index / width), __int2float_rn(height));
    // u = 0.75 * u - 0.375;
    u = __fmaf_rn(0.75, u, -0.375);
    // Try not to use if-else statement in kernel in future
    // Like use two kernels to calculate up-half and down-half seperately
    // And use fixed 'ratio' value to make calcualtion faster
    if (v < ratio) {
      // v = 0.25 - v / (2.0 * ratio);
      v = 0.25 - __fdividef(v, 2.0 * ratio);
    } else {
      // v = ((1.0 + ratio) * 0.5 - v) / (2.0 * (1.0 - ratio));
      v = __fdividef(__fmaf_rn(1.0 + ratio, 0.5, -v), 2.0 * (1.0 - ratio));
    }
    // u, v, 0 => su, cu, sv, cv, sin(0), cos(0)
    float su, cu, sv, cv;
    sincospif(2.0 * u, &su, &cu);
    sincospif(v, &sv, &cv);
    /* mat3(cu,    0,    -su,
            0,     1,     0,
            su,    0,     cu)
       mat3(1,     0,     0,
            0,     cv,    sv,
            0,    -sv,    cv) */
    /* float d00 = cu,      d01 = 0,   d02 = -su,
             d10 = su * sv, d11 = cv,  d12 = cu * sv,
             d20 = su * cv, d21 = -sv, d22 = cu * cv;
    /* mat3(cz,    sz,    0,
           -sz,    cz,    0,
            0,     0,     1) */
    // rotation matrix calcualtion
    /* float p00 = cu * cz + su * sv * sz,
             p01 = cv * sz,
             p02 = -su * cz + cu * sv * sz,
             p10 = cu * -sz + su * sv * cz,
             p11 = cv * cz,
             p12 = -su * -sz + cu * sv * cz,
             p20 = su * cv,
             p21 = -sv,
             p22 = cu * cv; */
    // vector 'ps'
    // float v00 = su * cv, v01 = -sv, v02 = cu * cv;
    // 0, 0, 1 -> 0, 0, -1
    // float v00 = -su * cv, v01 = sv, v02 = -cu * cv;
    float sy, cy, sp, cp, sr, cr;
    if (index < ratio * n) {
      // rotationMatrix(radians(vec3(pitch, yaw, -roll))) * ps
      y = CUDAradians(y);
      p = CUDAradians(p);
      r = CUDAradians(-r);
      sincosf(y, &sy, &cy);
      sincosf(p, &sp, &cp);
      sincosf(r, &sr, &cr);
      // rotation matrix calcualtion
      /* float p00 = cy * cr + sy * sp * sr,
               p01 = cp * sr,
               p02 = -sy * cr + cy * sp * sr,
               p10 = cy * -sr + sy * sp * cr,
               p11 = cp * cr,
               p12 = -sy * -sr + cy * sp * cr,
               p20 = sy * cp,
               p21 = -sp,
               p22 = cy * cp; */
      // vector 'ps'
      // float v00 = su * cv, v01 = -sv, v02 = cu * cv;
      // 0, 0, 1 -> 0, 0, -1
      // float v00 = -su * cv, v01 = sv, v02 = -cu * cv;
      float vx = (cy * cr + sy * sp * sr) * -su * cv + (cy * -sr + sy * sp * cr) * sv + sy * cp * -cu * cv,
            vy = cp * sr * -su * cv + cp * cr * sv + -sp * -cu * cv,
            vz = (-sy * cr + cy * sp * sr) * -su * cv + (-sy * -sr + cy * sp * cr) * sv + cy * cp * -cu * cv;
      u = atan2f(vx, vz);
      if (u < 0.0) u = u + M_PI + M_PI;
      v = acosf(vy);
      u = __fdividef(u, M_PI + M_PI);
      v = __fdividef(v, M_PI);
    } else {
      // rotationMatrix(radians(vec3(-pitch, yaw + 180.0, 90.0 + roll))) * ps
      y = CUDAradians(180.0 + y);
      p = CUDAradians(-p);
      r = CUDAradians(90.0 + r);
      sincosf(y, &sy, &cy);
      sincosf(p, &sp, &cp);
      sincosf(r, &sr, &cr);
      // rotation matrix calcualtion
      /* float p00 = cy * cr + sy * sp * sr,
               p01 = cp * sr,
               p02 = -sy * cr + cy * sp * sr,
               p10 = cy * -sr + sy * sp * cr,
               p11 = cp * cr,
               p12 = -sy * -sr + cy * sp * cr,
               p20 = sy * cp,
               p21 = -sp,
               p22 = cy * cp; */
      // vector 'ps'
      // float v00 = su * cv, v01 = -sv, v02 = cu * cv;
      // 0, 0, 1 -> 0, 0, -1
      // float v00 = -su * cv, v01 = sv, v02 = -cu * cv;
      float vx = (cy * cr + sy * sp * sr) * -su * cv + (cy * -sr + sy * sp * cr) * sv + sy * cp * -cu * cv,
            vy = cp * sr * -su * cv + cp * cr * sv + -sp * -cu * cv,
            vz = (-sy * cr + cy * sp * sr) * -su * cv + (-sy * -sr + cy * sp * cr) * sv + cy * cp * -cu * cv;
      u = atan2f(vx, vz);
      if (u < 0.0) u = u + M_PI + M_PI;
      v = acosf(vy);
      u = __fdividef(u, M_PI + M_PI);
      v = __fdividef(v, M_PI);
    }
    __syncthreads();
    cuda_transformed_data[index] = tex2D(tex_ref, u, v);
  }
}

__global__ void CUDAReformKernel(void) {}

int CUDARotateWrapper() {return 0;}

int CUDATransformWrapper(const uint8_t* data,
                         int width,
                         int height,
                         int target_width,
                         int target_height,
                         float yaw,
                         float pitch,
                         float roll,
                         uint8_t* transformed_data,
                         int flag) {
  // Use switch(flag) {} in future
  float ratio = target_width / (3.0 * target_height);
  int n = target_width * target_height;
  int tex_size = width * height;
  float* tex = (float*)malloc(tex_size * sizeof(float)); // temp
  for (int i = 0; i < tex_size; i++) *(tex + i) = (float)*(data + i); // temp
  cudaArray* cuArray;
  cudaMallocArray(&cuArray, &tex_ref.channelDesc, width, height);
  cudaMemcpyToArray(cuArray,
                    0, 0,
                    tex,
                    tex_size * sizeof(float),
                    cudaMemcpyHostToDevice);
  tex_ref.addressMode[0] = cudaAddressModeWrap;
  tex_ref.addressMode[1] = cudaAddressModeWrap;
  tex_ref.filterMode = cudaFilterModeLinear;
  tex_ref.normalized = true;
  cudaBindTextureToArray(tex_ref, cuArray);
  // Use float* to debug, future use int*
  float* cuda_transformed_data = NULL;
  if (cudaMalloc((void**)&cuda_transformed_data,
                  n * sizeof(float)) != cudaSuccess) {
    cerr << "cudaMalloc() Failed: cuda_transformed_data" << endl;
    return 1;
  }
  // To be modified depends on memory usage of each thread
  int n_threads = min(256, target_height);
  int n_blocks = (n + n_threads - 1) / n_threads;
  CUDATransformKernel<<<n_blocks, n_threads>>>(cuda_transformed_data,
                                               target_width,
                                               target_height,
                                               yaw,
                                               pitch,
                                               roll,
                                               ratio, n);
  if (cudaDeviceSynchronize() != cudaSuccess) {
    cerr << "cudaDeviceSynchronize() Failed" << endl;
    return 1;
  }
  if (cudaGetLastError() != cudaSuccess) {
    cout << "CUDA Kernel Failed" << endl;
    return 1;
  }
  // Same as cuda_transformed_data
  float* int_transformed_data = (float*)malloc(n * sizeof(float));
  if (int_transformed_data == NULL) {
    cerr << "Memory Allocation Failed: int_transformed_data" << endl;
    return 1;
  }
  memset(int_transformed_data, 0, n * sizeof(int));
  if (cudaMemcpy(int_transformed_data,
                 cuda_transformed_data,
                 n * sizeof(float),
                 cudaMemcpyDeviceToHost) != cudaSuccess) {
    cerr << "cudaMemcpy() Failed" << endl;
    return 1;
  }
  // temp get transformed data
  for (int i = 0; i < n; i++) *(transformed_data + i) = (uint8_t)*(int_transformed_data + i);
  free(int_transformed_data);
  cudaUnbindTexture(tex_ref);
  cudaFreeArray(cuArray);
  if (cudaFree(cuda_transformed_data) != cudaSuccess) {
    cerr << "cudaFree() Failed" << endl;
    return 1;
  }
  return 0;
}

int CUDAReformWrapper() {return 0;}
