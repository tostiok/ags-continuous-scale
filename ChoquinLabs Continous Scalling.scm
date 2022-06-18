AGSScriptModule        �  Dictionary* scaleCacheDictionary;
CL_ContinuousScaling* roomContinuousScaling;

function CacheClearScale()
{
  if (scaleCacheDictionary) {
    scaleCacheDictionary.Clear();
  }
}

int CacheGetScale(int x,  int y) {
  if (!MODULE_CL_CONTINOUS_SCALING_CACHE || scaleCacheDictionary == null) return -1;
  String cachedValue = scaleCacheDictionary.Get(String.Format("%d;%d", x >>MODULE_CL_CONTINOUS_SCALING_RESOLUTION,  y >> MODULE_CL_CONTINOUS_SCALING_RESOLUTION));
  if (cachedValue == null) {
    return -1;
  }

  return cachedValue.AsInt;
}

int CacheSetScale(int x,  int y,  int scale) {
  if (!MODULE_CL_CONTINOUS_SCALING_CACHE) return;
  if (scaleCacheDictionary == null) scaleCacheDictionary = Dictionary.Create();
  
  scaleCacheDictionary.Set(String.Format("%d;%d", x >> MODULE_CL_CONTINOUS_SCALING_RESOLUTION,  y >> MODULE_CL_CONTINOUS_SCALING_RESOLUTION),  String.Format("%d", scale));
}

static CL_ContinuousScaling* CL_ContinuousScaling::Create()
{
  CL_ContinuousScaling* cs = new CL_ContinuousScaling;
  cs.active = true;
  
  return cs;
}

function CL_ContinuousScaling::AddPoint(int x,  int y,  int scale)
{
  this.pointX[this.pointCount] = x;
  this.pointY[this.pointCount] = y;
  this.pointScale[this.pointCount] = scale;
  this.pointCount++;
  this.isPowerBaseCalculated = false;
}

float Distance(int x0,  int y0,  int x1,  int y1) {
  return Maths.Sqrt(Maths.RaiseToPower(IntToFloat(x1 - x0),  2.0) + Maths.RaiseToPower(IntToFloat(y1 - y0),  2.0));
}

float MinDistance(Point* a,  Point* points[],  int pointCount) {
  float minDistance = 0.0;
  for (int i = 0 ; i < pointCount ; i++) {
    float distance = Distance(a.x,  a.y,  points[i].x,  points[i].y);
    if (i == 0) {
      minDistance = Distance(a.x,  a.y,  points[i].x,  points[i].y);
    } else {
      if (distance < minDistance){
        minDistance = distance;
      }
    }
  }
  
  return minDistance;
}

float GetExp(float distance) {
  return Maths.RaiseToPower(MODULE_CL_CONTINOUS_SCALING_CURVE_SLOPE,  1.0 / distance);
}

String FloatArrToString(float arr[],  int count) {
  String result = "";
  for (int i = 0; i <count; i++) {
    if (i > 0) result = result.Append(";");
    result = result.Append(String.Format("%f", arr[i]));
  }
  return result;
}

function Scale(int i) {
  return i >> MODULE_CL_CONTINOUS_SCALING_RESOLUTION;
}

protected function CL_ContinuousScaling::CalcPowerBases() {

  for (int i = 0 ; i < this.pointCount ; i++) {
    Point* points[] = new Point[this.pointCount-1];
    int b = 0;
    for (int a = 0 ; a < this.pointCount; a++) {
      if (a != i) {
        points[b] = Point.CL_Create(Scale(this.pointX[a]),  Scale(this.pointY[a]));
        b++;
      }
    }    
    float powerBase = GetExp(MinDistance(Point.CL_Create(Scale(this.pointX[i]), Scale(this.pointY[i])),  points,  this.pointCount - 1));
    this.powerBases[i] = powerBase;
  }
  this.isPowerBaseCalculated = false;
}

protected float  CL_ContinuousScaling::GetPowerBase(int i) {
  if (!this.isPowerBaseCalculated) {
    this.CalcPowerBases();
  }
  return this.powerBases[i];
}

int CL_ContinuousScaling::GetScaleAt(int x,  int y)
{
  if (Scale(x) == this.lastX && Scale(y) == this.lastY) {
    return this.lastScale;
  }
  
  int cachedScale = CacheGetScale(x,  y);
  if (cachedScale == -1) {
    
    float totalWeight = 0.0;
    float scale = 0.0;
    for (int i = 0 ; i < this.pointCount ; i++) {
      if (Scale(this.pointX[i]) == Scale(x) && Scale(this.pointY[i]) == Scale(y)) return this.pointScale[i];
      float distance = Distance(Scale(x), Scale(y),  Scale(this.pointX[i]),  Scale(this.pointY[i]));
      float powerBase = this.GetPowerBase(i);
      float weight = Maths.RaiseToPower(powerBase,  distance);
      totalWeight += weight;
      scale += IntToFloat(this.pointScale[i]) * weight;
    }
    if (totalWeight) {
    scale = scale / totalWeight;
    }
    
    cachedScale = FloatToInt(scale);
    CacheSetScale(x,  y,  cachedScale);
  }
  this.lastX = Scale(x);
  this.lastY = Scale(y);
  this.lastScale = cachedScale;
  
  return cachedScale;
}

function ApplyRoomContinousScaling() 
{
  CL_ContinuousScaling* cs = roomContinuousScaling;
  if (cs != null && cs.active) {
    int scale = cs.GetScaleAt(player.x,  player.y);
    player.ManualScaling = true;
    player.Scaling = scale;
  } else {
    player.ManualScaling = false;
  }
}


//////////////////

function CL_SetContinousScaling(static Room,  CL_ContinuousScaling* cs) {
  if (roomContinuousScaling != cs) {
    CacheClearScale();
  }
  roomContinuousScaling = cs;
  ApplyRoomContinousScaling();
}

//////////////////

function late_repeatedly_execute_always()
{
  ApplyRoomContinousScaling();
}



function on_event(EventType event,  int data) {
  switch (event) {
    case eEventLeaveRoom:
      Room.CL_SetContinousScaling(null);
    break;
  }
}
 '  #define MODULE_CL_CONTINOUS_SCALING 1.0
#define MODULE_CL_CONTINOUS_SCALING_1.0
#define MODULE_CL_CONTINOUS_SCALING_MAX_POINTS 5
#define MODULE_CL_CONTINOUS_SCALING_CURVE_SLOPE 0.1
#define MODULE_CL_CONTINOUS_SCALING_RESOLUTION 5
#define MODULE_CL_CONTINOUS_SCALING_CACHE true

managed struct CL_ContinuousScaling {
  int pointX[MODULE_CL_CONTINOUS_SCALING_MAX_POINTS];
  int pointY[MODULE_CL_CONTINOUS_SCALING_MAX_POINTS];
  int pointScale[MODULE_CL_CONTINOUS_SCALING_MAX_POINTS];
  protected int pointCount;
  protected bool isPowerBaseCalculated;
  protected float powerBases[MODULE_CL_CONTINOUS_SCALING_MAX_POINTS];
  protected int lastX;
  protected int lastY;
  protected int lastScale;
  
  bool active;
  
  import static CL_ContinuousScaling* Create();
  import function AddPoint(int x,  int y,  int scale);
  import int GetScaleAt(int x,  int y);
  
  import protected function CalcPowerBases();
  import protected float GetPowerBase(int i);
};

import function CL_SetContinousScaling(static Room,  CL_ContinuousScaling* cs); +�l        fj����  ej��