/** 
 * @file
 * @brief OpenCL GPU kernels and data structures for PredPrey simulation.
 * 
 * The kernels in this file expect the following preprocessor defines:
 * 
 * * VW_INT - Vector size used for integers 
 * * REDUCE_GRASS_NUM_WORKGROUPS - Number of work groups in grass reduction step 1 (equivalent to get_num_groups(0)), but to be used in grass reduction step 2.
 * * CELL_NUM - Number of cells in simulation
 * 
 * * INIT_SHEEP - Initial number of sheep.
 * * SHEEP_GAIN_FROM_FOOD - Sheep energy gain when eating grass.
 * * SHEEP_REPRODUCE_THRESHOLD - Energy required for sheep to reproduce.
 * * SHEEP_REPRODUCE_PROB - Probability (between 1 and 100) of sheep reproduction.
 * * INIT_WOLVES - Initial number of wolves.
 * * WOLVES_GAIN_FROM_FOOD - Wolves energy gain when eating sheep.
 * * WOLVES_REPRODUCE_THRESHOLD - Energy required for wolves to reproduce.
 * * WOLVES_REPRODUCE_PROB - Probability (between 1 and 100) of wolves reproduction.
 * * GRASS_RESTART - Number of iterations that the grass takes to regrow after being eaten by a sheep.
 * * GRID_X - Number of grid columns (horizontal size, width). 
 * * GRID_Y - Number of grid rows (vertical size, height). 
 * * ITERS - Number of iterations. 
 * */

#include "PredPreyCommon_Kernels.cl"

/* Char vector width pre-defines */
#if VW_CHAR == 1
	#define VW_CHAR_ZERO 0
	#define VW_CHAR_SUM(x) (x)
	#define convert_ucharx(x) convert_uchar(x)
	typedef uchar ucharx;
#elif VW_CHAR == 2
	#define VW_CHAR_ZERO (uchar2) (0, 0)
	#define VW_CHAR_SUM(x) (x.s0 + x.s1)
	#define convert_ucharx(x) convert_uchar2(x)
	typedef uchar2 ucharx;
#elif VW_CHAR == 4
	#define VW_CHAR_ZERO (uchar4) (0, 0, 0, 0)
	#define VW_CHAR_SUM(x) (x.s0 + x.s1 + x.s2 + x.s3)
	#define convert_ucharx(x) convert_uchar4(x)
	typedef uchar4 ucharx;
#elif VW_CHAR == 8
	#define VW_CHAR_ZERO (uchar8) (0, 0, 0, 0, 0, 0, 0, 0)
	#define VW_CHAR_SUM(x) (x.s0 + x.s1 + x.s2 + x.s3 + x.s4 + x.s5 + x.s6 + x.s7)
	#define convert_ucharx(x) convert_uchar8(x)
	typedef uchar8 ucharx;
#elif VW_CHAR == 16
	#define VW_CHAR_ZERO (uchar16) (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
	#define VW_CHAR_SUM(x) (x.s0 + x.s1 + x.s2 + x.s3 + x.s4 + x.s5 + x.s6 + x.s7 + x.s8 + x.s9 + x.sa + x.sb + x.sc + x.sd + x.se + x.sf)
	#define convert_ucharx(x) convert_uchar16(x)
	typedef uchar16 ucharx;
#endif

/* Integer vector width pre-defines */
#if VW_INT == 1
	#define VW_INT_ZERO 0
	#define VW_INT_SUM(x) (x)
	#define convert_uintx(x) convert_uint(x)
	typedef uint uintx;
#elif VW_INT == 2
	#define VW_INT_ZERO (uint2) (0, 0)
	#define VW_INT_SUM(x) (x.s0 + x.s1)
	#define convert_uintx(x) convert_uint2(x)
	typedef uint2 uintx;
#elif VW_INT == 4
	#define VW_INT_ZERO (uint4) (0, 0, 0, 0)
	#define VW_INT_SUM(x) (x.s0 + x.s1 + x.s2 + x.s3)
	#define convert_uintx(x) convert_uint4(x)
	typedef uint4 uintx;
#elif VW_INT == 8
	#define VW_INT_ZERO (uint8) (0, 0, 0, 0, 0, 0, 0, 0)
	#define VW_INT_SUM(x) (x.s0 + x.s1 + x.s2 + x.s3 + x.s4 + x.s5 + x.s6 + x.s7)
	#define convert_uintx(x) convert_uint8(x)
	typedef uint8 uintx;
#elif VW_INT == 16
	#define VW_INT_ZERO (uint16) (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
	#define VW_INT_SUM(x) (x.s0 + x.s1 + x.s2 + x.s3 + x.s4 + x.s5 + x.s6 + x.s7 + x.s8 + x.s9 + x.sa + x.sb + x.sc + x.sd + x.se + x.sf)
	#define convert_uintx(x) convert_uint16(x)
	typedef uint16 uintx;
#endif

/* Char to vector conversion pre-defines */
#if VW_CHAR2INT_MUL == 1
	#define VW_CHAR2INT(c) convert_uintx(c)
#elif VW_CHAR2INT_MUL == 2
	#define VW_CHAR2INT(c) convert_uintx(c.hi + c.lo)
#elif VW_CHAR2INT_MUL == 4
	#define VW_CHAR2INT(c) convert_uintx((c.hi + c.lo).hi + (c.hi + c.lo).lo)
#elif VW_CHAR2INT_MUL == 8
	#define VW_CHAR2INT(c) convert_uintx( \
			((c.hi + c.lo).hi + (c.hi + c.lo).lo).hi +  \
			((c.hi + c.lo).hi + (c.hi + c.lo).lo).lo)
#elif VW_CHAR2INT_MUL == 16
	#define VW_CHAR2INT(c) convert_uintx( \
				( \
					((c.hi + c.lo).hi + (c.hi + c.lo).lo).hi +  \
					((c.hi + c.lo).hi + (c.hi + c.lo).lo).lo \
				).hi + \
				( \
					((c.hi + c.lo).hi + (c.hi + c.lo).lo).hi +  \
					((c.hi + c.lo).hi + (c.hi + c.lo).lo).lo \
				).lo \
			)
#endif


/**
 * @brief Initialize grid cells. 
 * 
 * @param grass_alive "Is grass alive?" array.
 * @param grass_timer Grass regrowth timer array.
 * @param seeds RNG seeds.
 * */
__kernel void initCell(
			__global uchar *grass_alive, 
			__global ushort *grass_timer, 
			__global rng_state *seeds)
{
	
	/* Grid position for this work-item */
	uint gid = get_global_id(0);

	/* Check if this workitem will initialize a cell... */
	if (gid < CELL_NUM) {
		/* ...yes, it will. */
		if (randomNextInt(seeds, 2)) {
			/* Grass is alive */
			grass_alive[gid] = 1;
			grass_timer[gid] = 0;
		} else {
			/* Grass is dead */
			grass_alive[gid] = 0;
			grass_timer[gid] = randomNextInt(seeds, GRASS_RESTART) + 1;
		}
	} else if (gid < PP_NEXT_MULTIPLE(CELL_NUM, VW_INT)) {
		/* Make sure that grass in padding cells are dead so
		 * they're not incorrectly counted in the reduction step. */
		grass_alive[gid] = 0;
	}
	
}

/**
 * @brief Intialize agents.
 * 
 * @param x
 * @param y
 * @param alive
 * @param energy
 * @param type
 * @param seeds
 * */
__kernel void initAgent(
			__global ushort *x,
			__global ushort *y,
			__global uchar *alive,
			__global ushort *energy,
			__global uchar *type,
			__global rng_state *seeds
) 
{
	/* Agent to be handled by this workitem. */
	uint gid = get_global_id(0);
	
	/* Determine what this workitem will do. */
	if (gid < INIT_SHEEP + INIT_WOLVES) {
		/* This workitem will initialize an alive agent. */
		x[gid] = randomNextInt(seeds, GRID_X);
		y[gid] = randomNextInt(seeds, GRID_Y);
		alive[gid] = 1;
		/* The remaining parameters depend on the type of agent. */
		if (gid < INIT_SHEEP ) {
			/* A sheep agent. */
			type[gid] = SHEEP_ID;
			energy[gid] = randomNextInt(seeds, SHEEP_GAIN_FROM_FOOD * 2) + 1;
		} else {
			/* A wolf agent. */
			type[gid] = WOLF_ID;
			energy[gid] = randomNextInt(seeds, WOLVES_GAIN_FROM_FOOD * 2) + 1;
		}
	} else {
		/* This workitem will initialize a dead agent with no type. */
		alive[gid] = 0;
	}
}


/**
 * @brief Grass kernel.
 * 
 * @param grass_alive
 * @param grass_timer
 * */
__kernel void grass(
			__global uchar *grass_alive, 
			__global ushort *grass_timer)
{
	/* Grid position for this workitem */
	uint gid = get_global_id(0);

	/* Check if this workitem will do anything */
	if (gid < CELL_NUM) {
		
		/* Decrement counter if grass is dead */
		if (!grass_alive[gid]) {
			ushort timer = --grass_timer[gid];
			if (timer == 0) {
				grass_alive[gid] = 1;
			}
		}
	}
}

/**
 * @brief Grass reduction kernel, part 1.
 * 
 * @param grass_alive
 * @param partial_sums
 * @param reduce_grass_global
 * */
__kernel void reduceGrass1(
			__global ucharx *grass_alive,
			__local uintx *partial_sums,
			__global uintx *reduce_grass_global) {
				
	/* Global and local work-item IDs */
	uint gid = get_global_id(0);
	uint lid = get_local_id(0);
	uint group_size = get_local_size(0);
	uint global_size = get_global_size(0);
	
	/* Serial sum */
	ucharx sum = VW_CHAR_ZERO;
	
	/* Serial count */
	uint cellVectorCount = PP_DIV_CEIL(CELL_NUM, VW_CHAR);
	uint serialCount = PP_DIV_CEIL(cellVectorCount, global_size);
	for (uint i = 0; i < serialCount; i++) {
		uint index = i * global_size + gid;
		if (index < cellVectorCount) {
			sum += grass_alive[index];
		}
	}
	
	/* Put serial sum in local memory */
	partial_sums[lid] = VW_CHAR2INT(sum); 
	
	/* Wait for all work items to perform previous operation */
	barrier(CLK_LOCAL_MEM_FENCE);
	
	/* Reduce */
	for (int i = group_size / 2; i > 0; i >>= 1) {
		if (lid < i) {
			partial_sums[lid] += partial_sums[lid + i];
		}
		barrier(CLK_LOCAL_MEM_FENCE);
	}

	/* Put in global memory */
	if (lid == 0) {
		reduce_grass_global[get_group_id(0)] = partial_sums[0];
	}
		
}

/**
 * @brief Grass reduction kernel, part 2.
 * 
 * @param reduce_grass_global
 * @param partial_sums
 * @param stats
 * */
 __kernel void reduceGrass2(
			__global uintx *reduce_grass_global,
			__local uintx *partial_sums,
			__global PPStatisticsOcl *stats) {
				
	/* Global and local work-item IDs */
	uint lid = get_local_id(0);
	uint group_size = get_local_size(0);
	
	/* Load partial sum in local memory */
	if (lid < REDUCE_GRASS_NUM_WORKGROUPS)
		partial_sums[lid] = reduce_grass_global[lid];
	else
		partial_sums[lid] = VW_INT_ZERO;
	
	/* Wait for all work items to perform previous operation */
	barrier(CLK_LOCAL_MEM_FENCE);
	
	/* Reduce */
	for (int i = group_size / 2; i > 0; i >>= 1) {
		if (lid < i) {
			partial_sums[lid] += partial_sums[lid + i];
		}
		barrier(CLK_LOCAL_MEM_FENCE);
	}
	
	/* Put in global memory */
	if (lid == 0) {
		stats[0].grass = VW_INT_SUM(partial_sums[0]);
		stats[0].sheep = 2;
		stats[0].wolves = 5;
	}
		
}

///**
 //* @brief Agent reduction kernel, part 1.
 //* 
 //* @param alive
 //* @param type 
 //* @param max_agents Maximum possible alive agents
 //* @param partial_sums
 //* @param reduce_agent_global
 //* */
//__kernel void reduceAgent1(
			//__global ucharx *alive,
			//__global ucharx *type,
			//__local uintx *partial_sums,
			//__global uintx *reduce_agent_global) {
				
	///* Global and local work-item IDs */
	//uint gid = get_global_id(0);
	//uint lid = get_local_id(0);
	//uint group_size = get_local_size(0);
	//uint global_size = get_global_size(0);
	
	///* Serial sum */
	//ucharx sumSheep = VW_INT_ZERO;
	//ucharx sumWolves = VW_INT_ZERO;
	
	///* Serial count */
	//uint serialCount = PP_DIV_CEIL((stats[0].sheep + stats[0].wolves) * 2, global_size);
	//for (uint i = 0; i < serialCount; i++) {
		//uint index = i * global_size + gid;
		//sumSheep += convert_uintx(alive[index] * type[index] ^ SHEEP_ID);
	//}
	
	///* Put serial sum in local memory */
	//partial_sums[lid] = sum; 
	
	///* Wait for all work items to perform previous operation */
	//barrier(CLK_LOCAL_MEM_FENCE);
	
	///* Reduce */
	//for (int i = group_size / 2; i > 0; i >>= 1) {
		//if (lid < i) {
			//partial_sums[lid] += partial_sums[lid + i];
		//}
		//barrier(CLK_LOCAL_MEM_FENCE);
	//}

	///* Put in global memory */
	//if (lid == 0) {
		//reduce_grass_global[get_group_id(0)] = partial_sums[0];
	//}
		
//}




