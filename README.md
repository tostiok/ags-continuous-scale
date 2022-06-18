# ags-continuous-scale
For each Walkable Area in the room, this module lets you define 2 or more points with scale values.
The character and objects laying on the walkable area will scale proportionally to the distance of each defined point.

This allows you to have complex continuous scalling regions, and not only vertical continuous scalling.
For example, if you have a walkable area in the lower part of the room, far away, and you can climb and get closer to the camera, you can set a point on the lower part of the screen of scale 50, and another point with scale 100 on the upper part of the room.

## Instalation
Import ChoquinLabs


## Usage

On each room load you want to define Complex Continuous Scalling:
```
function room_Load()
{
  CL_ContinuousScaling* cs1; // a continuous scalling for walkable area 1
  CL_ContinuousScaling* cs2; // a continuous scalling for walkable area 2

  cs1 = CL_ContinuousScaling.Create();
  cs1.AddPoint(712, 1094, 30);  // one point on room coordinates (712;1094) and scale 30
  cs1.AddPoint(1640, 908, 20);  // one point on room coordinates (1640;908) and scale 20
  
  cs2 = CL_ContinuousScaling.Create();
  cs2.AddPoint(374, 1052,  50);
  cs2.AddPoint(726, 1268,  100);
  
  Room.CL_SetContinousScaling(1,  cs1); // define continuous scale for walkable area 1
  Room.CL_SetContinousScaling(2,  cs2); // define continuous scale for walkable area 2
}
```
