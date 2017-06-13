float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

float lengthRound(vec3 p)
{
	float n = 1.7;
	return pow(pow(p.x,n) + pow(p.y,n) + pow(p.z,n), 1.0/n);
}

float smin( float a, float b, float k )
{
    float res = exp( -k*a ) + exp( -k*b );
    return -log( res )/k;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

vec3 repeatPos(vec3 p, vec3 c)
{
	return mod(p,c)-.5 * c;
}

float getDistance(vec3 position)
{	
    vec3 pos = vec3
        (
            (position.x + 5.0 * sin(iGlobalTime)) - 2.0,
            position.y + 5.0 * cos(iGlobalTime),
            position.z - 1.5
        );
    
    vec3 pos2 = vec3
        (
            (position.x + 5.0 * sin(iGlobalTime)) - 2.0,
            position.y + 5.0 * cos(iGlobalTime),
            position.z - 1.5
        );
    vec3 pos3 = vec3
        (
            position.x + 45.,
            position.y - 52. - iGlobalTime * 5.,
            position.z + 55.0
        );
        
    vec3 floorPos = vec3
        (
            position.x,
            position.y + 5.0,
            position.z
        );
    
    vec3 wallPos = vec3
        (
            position.x,
            position.y + 5.0,
            position.z - 25.
        );
    
    pos3 = repeatPos(pos3, vec3(15.,15.,15.));
    
    float floorDis = sdBox(floorPos, vec3(300, 1, 300));
    float wallDis = sdBox(wallPos, vec3(300, 100, 1));
    
    
    
    float sphereDis = sdSphere(pos3, 1.);  
    float distance = smin(floorDis, sphereDis, 1.0);
    
    distance = smin(distance, floorDis, 0.5);
    distance = min(distance, wallDis);
   
   return distance;
    
    //Draw cubes
	//return sdBox(repPos, vec3(1.,1.,1.));
	
    //Draw spheres
	//return sdSphere(repPos, 1.0);
}

vec4 getColor(vec3 position)
{
	float e = 0.001;
	float f0 = getDistance(position);
	
    //Approximate the normal by stepping a minimal amount in each of the axes' direction
	float fx = getDistance(vec3(position.x + e, position.y, position.z));
	float fy = getDistance(vec3(position.x, position.y + e, position.z));
	float fz = getDistance(vec3(position.x, position.y, position.z + e));
	
	
	
	vec3 normal = normalize(vec3(fx - f0, fy - f0, fz - f0));
	vec3 lightPosition = vec3
		(
			0.0, 
			20.0,
      -5.0            
		);
	vec3 lightDir = normalize(lightPosition - position);
    vec4 lightColor = vec4
    (
        0.15,
        0.2,
        0.3,
        0.2
    );
	vec4 lightIntensity = lightColor * dot(normal, lightDir);
	float reflectance = 0.5;
	
	float lightDistance = length(position-lightPosition);
    
  float distanceIntensity = (5.0 / (pow(lightDistance / 25.0, 1.0001))); 
	
	return reflectance * lightIntensity * (distanceIntensity);
	
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{    
  	vec3 eye = vec3(0, 0, -15);
    vec3 up = vec3(0, 1, 0);
    vec3 right = vec3(1, 0, 0);
    
    float epsilon = 0.1;
    float maxDistance = 10000.0;

	  // Normalized device coordinates
	  vec2 ndcXY = -1.0 + 2.0 * fragCoord.xy / iResolution.xy;
    
	  float aspectRatio = iResolution.x / iResolution.y;
	
	// scaled XY which fits the aspect ratio
	vec2 uv = ndcXY * vec2( aspectRatio, 1.0 );

    float focalLength = 1.0;
    vec3 forward = normalize(cross(right, up));
    
    vec3 planePos = right * uv.x + up * uv.y;
	
    vec3 pImagePlane = eye + forward * focalLength + planePos;
    vec3 rayDirection = normalize(pImagePlane - eye);

	// "Sky" color
    vec4 color = vec4
		(
			0.30,
			0.30,
			0.30,
			1
		); 

    float t = 0.0;
    const float maxSteps = 512.0;
    for(float i = 0.0; i < maxSteps; ++i)
    {
        vec3 p = pImagePlane + rayDirection * t;
		float d = getDistance(p);
		if(d > maxDistance) {break;}
        if(d < epsilon)
        {
			      color = getColor(p);
            break;
        }
		    //March forward by the distance to the closest surface to current point
        t += d;
    }

    fragColor = color;
}

// VR entrypoint
void mainVR( out vec4 fragColor, in vec2 fragCoord, in vec3 fragRayOri, in vec3 fragRayDir)
{    
	  vec3 eye = vec3(0, 0, -15);
    vec3 up = vec3(0, 1, 0);
    vec3 right = vec3(1, 0, 0);
    float epsilon = 0.1;
    float maxDistance = 100000.0;
    
    vec2 ndcXY = -1.0 + 2.0 * fragCoord.xy / iResolution.xy;
    float aspectRatio = iResolution.x / iResolution.y;
    // scaled XY which fits the aspect ratio
    vec2 uv = ndcXY * vec2( aspectRatio, 1.0 );
    
    float focalLength = 1.0;
    vec3 forward = normalize(cross(right, up));
    
    vec3 planePos = right * uv.x + up * uv.y;
	
    vec3 pImagePlane = eye + forward * focalLength + planePos;
    vec3 rayDirection = -fragRayDir;

	// Sky color
    vec4 color = vec4
		(
			0.30,
			0.30,
			0.30,
			1
		); 

    float t = 0.0;
    const float maxSteps = 512.0;
    for(float i = 0.0; i < maxSteps; ++i)
    {
        vec3 p = pImagePlane + rayDirection * t;
		    float d = getDistance(p);
		    if(d > maxDistance) {break;}
        if(d < epsilon)
        {   
            //Shade this surface
			      color = getColor(p);
            break;
        }
		    // March forward by the distance to the closest surface to current point
        t += d;
    }

    fragColor = color;
}
