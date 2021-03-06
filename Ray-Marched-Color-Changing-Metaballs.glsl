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
  
  //float lengthRounded = lengthRound(max(d,0.0));
  //return min(max(d.x,max(d.y,d.z)),0.0) + lengthRounded;
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
            (position.x + 2.0 * sin(iGlobalTime)) - 2.0,
            position.y + 2.0 * cos(iGlobalTime),
            position.z - 0.5
        );
    
    vec3 pos2 = vec3
        (
            (position.x + 1.7 * cos(iGlobalTime)) + 2.0,
            position.y + 1.7 * sin(iGlobalTime),
            position.z
        );
    //vec3 pos3 = vec3(position.x + 1.8 * sin(iGlobalTime - 3.3) + 0.2, position.y + 1.8 * cos(iGlobalTime - 3.3), position.z - 0.5);
  
    
    
    
    float dis1 = sdSphere(pos, 2.0);
    
    float dis2 = sdSphere(pos2, 1.33);
    //float dis2 = sdBox(pos2, vec3(1., 1., 1.));
    
    
    
    //float dis3 = sdSphere(pos3, 0.2);
  
    
    float distance = smin(dis1, dis2, 1.0);
    //distance = min(distance, dis3);
  
    
    //return dis1;
    return distance;
    
    
    //return sdSphere(pos, 2.0);
    //Repeat shape
	//vec3 repPos = repeatPos(position, vec3(5.0,20.0,4.5));
    
    //Draw cubes
	//return sdBox(repPos, vec3(1.,1.,1.));
	
    //Draw spheres
	//return sdSphere(repPos, 1.0);
}

vec4 getColor(vec3 position)
{
	float e = 0.00001;
	float f0 = getDistance(position);
	
    //Approximate the normal by stepping a minimal amount in each of the axes' direction
	float fx = getDistance(vec3(position.x + e, position.y, position.z));
	float fy = getDistance(vec3(position.x, position.y + e, position.z));
	float fz = getDistance(vec3(position.x, position.y, position.z + e));
	
	
	
	vec3 normal = normalize(vec3(fx - f0, fy - f0, fz - f0));
	vec3 lightPosition = vec3
		(
			0.0, //+ 12.0*sin(iGlobalTime*1.0),
			0.0, //+ 12.0*sin(iGlobalTime*2.0),
            -3.0
            //iGlobalTime * 20.0
            
            //-1.0 - sin(iGlobalTime) * 2.0
			//280.0 + 300.0*sin(iGlobalTime*1.0) //Make the light move on the z axis
			//iGlobalTime * 5.0 + 100.0
		);
	vec3 lightDir = normalize(lightPosition - position);
	vec4 lightColor = vec4
        (
            (sin(iGlobalTime * 0.1) + 0.5)/ 10.0,
            (sin(iGlobalTime / 1.1) + 1.5)/ 10.0,
            (cos(iGlobalTime * 0.1) + 0.5)/ 10.0,
            //0.5 * tan(iGlobalTime),
            //0.5 - 0.5 * sin(iGlobalTime),
            //0.5 - 0.5 * cos(iGlobalTime),
            0.2);
	vec4 lightIntensity = lightColor * dot(normal, lightDir);
	float reflectance = 0.5;
	
	float lightDistance = length(position-lightPosition);
    
    //Hacky but pretty good looking light intensity diminishing over distance
	//float distanceIntensity = (1.0 / (pow(lightDistance / 100.0, 1.1))); 
    float distanceIntensity = (5.0 / (pow(lightDistance / 25.0, 1.0001))); 
	
	return reflectance * lightIntensity * (distanceIntensity);
	
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    //Moving eye position, bugs on some weaker hardware and just shows grey as mentioned in the omments
    //vec3 eye = vec3(0, 3, iGlobalTime * 20.0 - 50.0);
    
    //Still eye
	vec3 eye = vec3(0, 0, -5);
	//eye.z = -1.0*sin(iGlobalTime);
    vec3 up = vec3(0, 1, 0);
    vec3 right = vec3(1, 0, 0);
    
    //Epsilon for when we are close enough to a surface to decide the surface is right here
    float epsilon = 0.1;
    float maxDistance = 100000.0;

	//Normalized device coordinates
	vec2 ndcXY = -1.0 + 2.0 * fragCoord.xy / iResolution.xy;
	
	// aspect ratio
	float aspectRatio = iResolution.x / iResolution.y;
	
	// scaled XY which fits the aspect ratio
	vec2 uv = ndcXY * vec2( aspectRatio, 1.0 );
	//uv.y += (0.07 * sin(uv.x + iGlobalTime*4.0));

	
    
    //Variables needed for ray marching this pixel
    float focalLength = 1.0;
    vec3 forward = normalize(cross(right, up));
    
    vec3 planePos = right * uv.x + up * uv.y;
	
    vec3 pImagePlane = eye + forward * focalLength + planePos;
    vec3 rayDirection = normalize(pImagePlane - eye);

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
		
            //Fixed color, no shading
			//color = vec4(i*0.1+0.1,0.5,0,1);
            
            //Shade this surface
			color = getColor(p);
            break;
        }
		//March forward by the distance to the closest surface to current point in space
        t += d;
    }

    fragColor = color;
}