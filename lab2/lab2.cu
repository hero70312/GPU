#include "lab2.h"

// Macro functions - YUV and RGB converting.
#define clip(x) ((x) > 255 ? 255 : (x) < 0 ? 0 : (int)x)
#define RGBtoY(R, G, B) clip( ( 0.299 * R) + ( 0.587 * G) + ( 0.114 * B)      )
#define RGBtoU(R, G, B) clip( (-0.169 * R) + (-0.331 * G) + ( 0.500 * B) + 128)
#define RGBtoV(R, G, B) clip( ( 0.500 * R) + (-0.419 * G) + (-0.081 * B) + 128)

static const unsigned W = 1920;
static const unsigned H = 1080;
static const unsigned NFRAME = 240;

struct Vector3D
{
 unsigned char x, y, z;
 Vector3D(unsigned char x, unsigned char y, unsigned char z)
 {
  this->x = x;
  this->y = y;
  this->z = z;
 }
};

Lab2VideoInfo tmpInfo;
struct Lab2VideoGenerator::Impl {
 int t = 0;
};



Lab2VideoGenerator::Lab2VideoGenerator() : impl(new Impl) {
}

Lab2VideoGenerator::~Lab2VideoGenerator() {}

__global__ void PCG2()
{


}
__device__ int* PCGRecurOne(int x, int y, int t, int part)
{

 //printf("x = %d , y = %d ,cosx = %f\n ",x,y,cosf(x));
 int windowDis = H*H + W*W;
 int dis = x*x + y*y;
 float disMod = (float)dis / (float)windowDis;
 //printf("dixmod =%f ,%d \n", (255 * disMod), (int)(255 * disMod));
 if (part == 1)
 {
  int tmpt = t < 10 ? t = 10 : t;

  float func = cosf(2*(y + t)) + cosf(x + t);
  if (func < 0.1 && func> -0.1)
  {
   int RGB[3] = { 255, 255 * disMod, };
   //printf("1RGB = %d , %d , %d\n", RGB[0], RGB[1], RGB[2]);
   return RGB;
  }

  else
  {
   int RGB[3] = { -1, -1, -1 };
   //printf("3RGB = %d , %d , %d\n", RGB[0], RGB[1], RGB[2]);
   return RGB;
  }
 }
 int RGB[3] = { -1, -1, -1 };
 //printf("4RGB = %d , %d , %d\n", RGB[0], RGB[1], RGB[2]);
 return RGB;
}
__global__ void SetColor(uint8_t *yuv, int x1, int y1, int vectorX, int vectorY, int * color)
{
 int t = blockIdx.x * blockDim.x + threadIdx.x;
 y1 += vectorY / abs(vectorX)*t;
 x1 += vectorX / abs(vectorX)*t;
 int idx = (y1)*W + x1;
 if (idx > W*H || x1<0 || x1>W || y1<0 || y1>H)return;
 int rowOfY = (idx / W);
 int columnOfY = (idx%W);
 int rowOfUV = rowOfY / 2;
 int columnOfUV = columnOfY / 2;
 int uvWidth = W / 2;
 int uvIdx = rowOfUV *uvWidth + columnOfUV;

 yuv[idx] = RGBtoY(color[0], color[1], color[2]);
 yuv[W*H + uvIdx] = RGBtoU(color[0], color[1], color[2]);
 yuv[W*H + W*H / 4 + uvIdx] = RGBtoV(color[0], color[1], color[2]);

}
__device__ void Line(uint8_t *yuv, float x1, float y1, float x2, float y2, int * color)
{
 int idx = (int)y1*W + x1;
 //if (idx>W*H || x1<0 || x2<0 || x1>W || x2>W || y1<0 || y2<0 || y1>H || y2>H)return;

 int rowOfY = (idx / W);
 int columnOfY = (idx%W);
 int rowOfUV = rowOfY / 2;
 int columnOfUV = columnOfY / 2;
 int uvWidth = W / 2;
 int uvIdx = rowOfUV *uvWidth + columnOfUV;
 float vectorX = x2 - x1;
 float vectorY = y2 - y1;
 //SetColor << <1, abs(vectorX) >> >(yuv,x1,y1, vectorX, vectorY, color);

 int dist = 0;
 int maxDis = H;

 for (int i = 0; i < abs(vectorX); i++)
 {
  if (idx>W*H || x1<0 || x2<0 || x1>W || x2>W || y1<0 || y2<0 || y1>H || y2>H)continue;

  dist = y1;


  yuv[idx] = RGBtoY(255 - 100 * dist / maxDis, 0, 0);
  yuv[W*H + uvIdx] = RGBtoU(255 - 100 * dist / maxDis, 0, 0);
  yuv[W*H + W*H / 4 + uvIdx] = RGBtoV(255 - 100 * dist / maxDis, 0, 0);


  y1 += vectorY / abs(vectorX);
  x1 += vectorX / abs(vectorX);
  idx = (int)(y1)*W + x1;
  rowOfY = (idx / W);
  columnOfY = (idx%W);
  rowOfUV = rowOfY / 2;
  columnOfUV = columnOfY / 2;
  uvWidth = W / 2;
  uvIdx = rowOfUV *uvWidth + columnOfUV;
 }
}

__global__ void PCGRecur(int beginX, int beginY, int x, int y, uint8_t *yuv, int t, int orginIdx, int recurId, int caseID){


 int idx = blockIdx.x * blockDim.x + threadIdx.x;
 int locateIdx = y * W + x;
 int width = x;
 int height = y;


 int tPCG = t;
 int recurIdx = recurId;

 int origWidth = orginIdx%W;
 int origHeight = orginIdx / W;
 int uvWidth = width / 2;
 int uvHeight = height / 2;
 int origUVWidth = origWidth / 2;
 int origUIHeight = origHeight / 2;
 int uvIdx = uvWidth + uvHeight * (W / 2);

 int RGB[3] = { 0, 0, 255 };

 if (recurId == 0)
 {
  Line(yuv, beginX, beginY, width, height, RGB);
  return;
 }
 int movx = 0;
 int movy = 0;
 width + t > W ? movx = W : movx = width + t;
 height + t > H ? movy = H : movy = height + t;

 width - t < 0 ? movx = 0 : movx = width - t;
 height - t < H ? movy = 0 : movy = height - t;


 PCGRecur << <2, 4 >> >(beginX, beginY, width + t, height + t, yuv, tPCG, idx, recurIdx - 1, 0);
 //PCGRecur << <2, 1 >> >(beginX, beginY, width + t, height - t, yuv, tPCG, idx, recurIdx - 1, 0);
 //PCGRecur << <2, 1 >> >(beginX, beginY, width - t, height + t, yuv, tPCG, idx, recurIdx - 1, 0);
 //PCGRecur << <2, 1 >> >(beginX, beginY, width - t, height - t, yuv, tPCG, idx, recurIdx - 1, 0);
}
__global__ void PCG(Lab2VideoInfo &info, uint8_t * yuv, int tt)
{
 int t = tt;
 int idx = blockIdx.x * blockDim.x + threadIdx.x;

 int tPCG = t;
 //PCG2 << < 1, 1 >> > ();
 int width = idx % W;
 int height = idx / W;

 int uvWidth = width / 2;
 int uvHeight = height / 2;

 int uvIdx = uvWidth + uvHeight * (W / 2);
 int modT = t < 230 ? 240 - t : 0;
 int RGB[3] = { -1, -1, -1 };
 //int RGB[3] = { 255, 0, 0 };
 int *RGBtmp;
 for (int i = 1; i <= 1; i++)
 {

  if (i == 1) RGBtmp = PCGRecurOne(width, height, modT, i);

  for (int j = 0; j < 3; j++)
  {
   RGB[j] = RGBtmp[j];
  }

 }

 if (RGB[0] == -1 || RGB[1] == -1 || RGB[2] == -1) return;

 yuv[idx] = (int)RGBtoY(RGB[0], RGB[1], RGB[2]);
 yuv[W*H + uvIdx] = (int)RGBtoU(RGB[0], RGB[1], RGB[2]);
 yuv[W*H + W*H / 4 + uvIdx] = (int)RGBtoV(RGB[0], RGB[1], RGB[2]);


}

void Lab2VideoGenerator::get_info(Lab2VideoInfo &info) {
 info.w = W;
 info.h = H;
 info.n_frame = NFRAME;
 // fps = 24/1 = 24
 info.fps_n = 24;
 info.fps_d = 1;


 tmpInfo = info;
};
__global__ void subTriangle(uint8_t *yuv, int n, float x1, float y1, float x2, float y2, float x3, float y3, int it)
{
 int idx = blockIdx.x * blockDim.x + threadIdx.x;
 int dist = 0;
 int maxDis = H;
 int RGB_Black[3] = { 255 - 100 * dist / maxDis, 0, 0 };
 //Draw the 3 sides as black lines
 Line(yuv, x1, y1, x2, y2, RGB_Black);
 Line(yuv, x1, y1, x3, y3, RGB_Black);
 Line(yuv, x2, y2, x3, y3, RGB_Black);

 //Calls itself 3 times with new corners, but only if the current number of recursions is smaller than the maximum depth
 if (n < it)
 {
  //Smaller triangle 1
  if (idx == 0)
  {
   subTriangle << <3, 1 >> >
    (
    yuv,
    n + 1, //Number of recursions for the next call increased with 1
    (x1 + x2) / 2 + (x2 - x3) / 2, //x coordinate of first corner
    (y1 + y2) / 2 + (y2 - y3) / 2, //y coordinate of first corner
    (x1 + x2) / 2 + (x1 - x3) / 2, //x coordinate of second corner
    (y1 + y2) / 2 + (y1 - y3) / 2, //y coordinate of second corner
    (x1 + x2) / 2, //x coordinate of third corner
    (y1 + y2) / 2, //y coordinate of third corner*
    it
    );
  }
  //Smaller triangle 2
  if (idx == 1)
  {
   subTriangle << <3, 1 >> >
    (
    yuv,
    n + 1, //Number of recursions for the next call increased with 1
    (x3 + x2) / 2 + (x2 - x1) / 2, //x coordinate of first corner
    (y3 + y2) / 2 + (y2 - y1) / 2, //y coordinate of first corner
    (x3 + x2) / 2 + (x3 - x1) / 2, //x coordinate of second corner
    (y3 + y2) / 2 + (y3 - y1) / 2, //y coordinate of second corner
    (x3 + x2) / 2, //x coordinate of third corner
    (y3 + y2) / 2,  //y coordinate of third corner
    it);
   //Smaller triangle 3
  }
  if (idx == 2)
  {
   subTriangle << <3, 1 >> >
    (
    yuv,
    n + 1, //Number of recursions for the next call increased with 1
    (x1 + x3) / 2 + (x3 - x2) / 2, //x coordinate of first corner
    (y1 + y3) / 2 + (y3 - y2) / 2, //y coordinate of first corner
    (x1 + x3) / 2 + (x1 - x2) / 2, //x coordinate of second corner
    (y1 + y3) / 2 + (y1 - y2) / 2, //y coordinate of second corner
    (x1 + x3) / 2, //x coordinate of third corner
    (y1 + y3) / 2,  //y coordinate of third corner
    it
    );
  }
 }
}
__global__ void drawSierpinski(uint8_t *yuv, float x1, float y1, float x2, float y2, float x3, float y3, int it)
{
 int RGB_Black[3] = {};
 //Draw the 3 sides of the triangle as black lines
 Line(yuv, x1, y1, x2, y2, RGB_Black);
 Line(yuv, x1, y1, x3, y3, RGB_Black);
 Line(yuv, x2, y2, x3, y3, RGB_Black);

 //Call the recursive function that'll draw all the rest. The 3 corners of it are always the centers of sides, so they're averages
 subTriangle << <3, 1 >> >
  (
  yuv,
  0, //This represents the first recursion
  (x1 + x2) / 2, //x coordinate of first corner
  (y1 + y2) / 2, //y coordinate of first corner
  (x1 + x3) / 2, //x coordinate of second corner
  (y1 + y3) / 2, //y coordinate of second corner
  (x2 + x3) / 2, //x coordinate of third corner
  (y2 + y3) / 2,  //y coordinate of third corner
  it);
}

//The recursive function that'll draw all the upside down triangles

void Lab2VideoGenerator::Generate(uint8_t *yuv) {
 Vector3D background_ColorRGB(255, 255, 255);
 //background
 //Y
 cudaMemset(yuv, RGBtoY(background_ColorRGB.x, background_ColorRGB.y, background_ColorRGB.z), W*H);
 //U
 cudaMemset(yuv + W*H, RGBtoU(background_ColorRGB.x, background_ColorRGB.y, background_ColorRGB.z), W*H / 4);
 //V
 cudaMemset(yuv + W*H + W*H / 4, RGBtoV(background_ColorRGB.x, background_ColorRGB.y, background_ColorRGB.z), W*H / 4);

 int block_dim = H*W / W;
 int iterNum = 9;
 int t = iterNum * impl->t / NFRAME;
 //cudaMemcpy(&t, &impl->t, sizeof(int), cudaMemcpyHostToDevice);
 PCG << <block_dim, W >> >(tmpInfo, yuv, t);
 drawSierpinski << <1, 1 >> >(yuv, 10, H - 10, W - 10, H - 10, W / 2, 10, t); //Call the sierpinski function (works with any corners inside the screen

 ++(impl->t);
}