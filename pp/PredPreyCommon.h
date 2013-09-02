/** 
 * @file
 * @brief Common data structures and function headers for PredPrey simulation.
 */

#ifndef PREDPREYCOMMON_H
#define PREDPREYCOMMON_H

#define CL_USE_DEPRECATED_OPENCL_1_1_APIS
#define __NO_STD_STRING

#include <CL/cl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <time.h>
#include <math.h>
#include <glib.h>
#include <argp.h>
#include <limits.h>
#include "clutils.h"
#include "gerrorf.h"
#include "bitstuff.h"
#include "clprofiler.h"

/** Sheep ID. */
#define SHEEP_ID 0

/** Wolf ID. */
#define WOLF_ID 1

/** Helper macros to convert int to string at compile time. */
#define STR_HELPER(x) #x
#define STR(x) STR_HELPER(x)

/** Default parameters file. */
#define PP_DEFAULT_PARAMS_FILE "config.txt"

/** Default statistics output file. */
#define PP_DEFAULT_STATS_FILE "stats.txt"

/** Default RNG seed. */
#define PP_DEFAULT_SEED 0

/** Default random number generator. */
#define PP_DEFAULT_RNG "lcg"

/** Available random number generators. */
#define PP_RNGS "lcg (default), xorshift, xorshift128 or mwc64x"

/** Kernel includes (to be added to OpenCL compiler options). */
#define PP_KERNEL_INCLUDES "-I pp "

/** Resolves to error category identifying string. Required by glib error reporting system. */
#define PP_ERROR pp_error_quark()

/** Perform direct OpenCL profiling if the C compiler has defined a 
 * CLPROFILER constant. */
#ifdef CLPROFILER
	#define QUEUE_PROPERTIES CL_QUEUE_PROFILING_ENABLE
#else
	#define QUEUE_PROPERTIES 0
#endif

/**
 * @brief Returns the requested information about a RNG.
 * 
 * @param i Loop variable.
 * @param rng_infos The array containing data about the RNGs.
 * @param rng_tag Tag identifying the RNG.
 * @param field Requested information about the RNG.
 * @return The requested information about a RNG.
 * */
#define PP_RNG_RETURN(i, rng_infos, rng_tag, field) \
	i = 0; \
	while(rng_infos[i].tag) { \
		if (g_strcmp0(rng_infos[i].tag, rng_tag) == 0) \
			return rng_infos[i].field; \
		i++; \
	} \
	return rng_infos[i].field; \

/**
 * @brief Performs integer division returning the ceiling instead of
 * the floor if it is not an exact division.
 * 
 * @param a Integer numerator.
 * @param b Integer denominator.
 * */
#define PP_DIV_CEIL(a, b) ((a + b - 1) / b)

/** 
 * @brief Calculates an adjusted global worksize equal or larger than 
 * the given global worksize and is a multiple of the given local 
 * worksize. 
 * 
 * @param gws Minimum global worksize.
 * @param lws Local worksize. 
 * */
#define PP_GWS_MULT(gws, lws) (lws * PP_DIV_CEIL(gws, lws))

/**
 * @brief Information about a RNG.
 * */	
typedef struct pp_rng_info {
	char* tag;            /**< Tag identifying the  TNG. */
	char* compiler_const; /**< RNG OpenCL compiler constant. */
	size_t bytes;         /**< Bytes required per RNG seed. */
} PPRngInfo;


/**
 * @brief Pointer to compare function to pass to pp_in_array() function.
 * 
 * @param elem1 First element to compare.
 * @param elem2 Second element to compare.
 * @return 0 if elements are equal, another value otherwise.
 */
typedef int (*cmpfunc)(void *elem1, void *elem2);

/**
 * @brief Program error codes.
 * */ 
enum pp_error_codes {
	PP_SUCCESS = 0,                     /**< Successfull operation. */
	PP_UNKNOWN_ARGS = -1,               /**< Unknown arguments. */
	PP_INVALID_ARGS = -2,               /**< Arguments are known but invalid. */
	PP_LIBRARY_ERROR = -3,              /**< Error in external library. */
	PP_UNABLE_TO_OPEN_PARAMS_FILE = -4, /**< Parameters file not found. */
	PP_INVALID_PARAMS_FILE = -5,        /**< Invalid parameters file. */
	PP_UNABLE_SAVE_STATS = -6           /**< Unable to save stats. */
};

/** 
 * @brief Simulation statistics.
 */
typedef struct pp_statistics {
	cl_uint sheep;   /**< Number of sheep. */
	cl_uint wolves;  /**< Number of wolves. */
	cl_uint grass;   /**< Quantity of grass. */
} PPStatistics;

/** 
 * @brief Simulation parameters.
 */
typedef struct pp_parameters {
	unsigned int init_sheep;                 /**< Initial number of sheep. */
	unsigned int sheep_gain_from_food;       /**< Sheep energy gain when eating grass. */
	unsigned int sheep_reproduce_threshold;  /**< Energy required for sheep to reproduce. */
	unsigned int sheep_reproduce_prob;       /**< Probability (between 1 and 100) of sheep reproduction. */
	unsigned int init_wolves;                /**< Initial number of wolves. */
	unsigned int wolves_gain_from_food;      /**< Wolves energy gain when eating sheep. */
	unsigned int wolves_reproduce_threshold; /**< Energy required for wolves to reproduce. */
	unsigned int wolves_reproduce_prob;      /**< Probability (between 1 and 100) of wolves reproduction. */
	unsigned int grass_restart;              /**< Number of iterations that the grass takes to regrow after being eaten by a sheep. */
	unsigned int grid_x;  /**< Number of grid columns (horizontal size, width). */
	unsigned int grid_y;  /**< Number of grid rows (vertical size, height). */
	unsigned int iters;   /**< Number of iterations. */
} PPParameters;

/** 
 * @brief Generic agent parameters.
 */
typedef struct pp_agent_params {
	cl_uint gain_from_food;      /**< Agent energy gain when eating food. */
	cl_uint reproduce_threshold; /**< Energy required for agent to reproduce. */
	cl_uint reproduce_prob;      /**< Probability (between 1 and 100) of agent reproduction. */
} PPAgentParams;

/** @brief Load predator-prey simulation parameters. */
int pp_load_params(PPParameters* parameters, char * filename, GError** err);

/** @brief Show proper error messages. */
void pp_error_handle(GError* err, int status);

/** @brief Callback function which will be called when non-option 
 *  command line arguments are given. */
gboolean pp_args_fail(const gchar *option_name, const gchar *value, gpointer data, GError **err);

/** @brief Returns the proper OpenCL compiler constant for the provided
 * random number generator tag. */
const gchar* pp_rng_const_get(gchar *rng_tag);

/** @brief Returns the number of bytes required per seed per workitem 
 * for the provided random number generator tag. */
size_t pp_rng_bytes_get(gchar *rng_tag);

/** @brief Returns the next multiple of a given divisor which is equal or
 * larger than a given value. */
unsigned int pp_next_multiple(unsigned int value, unsigned int divisor);

/** @brief Resolves to error category identifying string, in this case
 *  an error related to the predator-prey simulation. */
GQuark pp_error_quark(void);

#endif
