/*
 * Copyright (c) 2015, Nuno Fachada
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *   * Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   * Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *   * Neither the name of the Instituto Superior Técnico nor the
 *     names of its contributors may be used to endorse or promote products
 *     derived from this software without specific prior written permission.
 *     
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

package org.laseeb.pphpc;

public class SimWorkProviderFactory {

	public static ISimWorkProvider createWorkProvider(SimWorkType workType, SimParams params, int numWorkers, int blockSize) {
		
		/* Grass initialization strategy. */
		ICellGrassInitStrategy grassInitStrategy = new CellGrassInitCoinRandCounter();
		
		/* Simulation space. */
		ISimSpace space = new Square2DTorusSimSpace(params.getGridX(), params.getGridY());
		
		/* Put agent strategy. */
		ICellPutAgentStrategy putAgentStrategy;
		
		/* Synchronizers.*/
		ISynchronizer afterInitSync, afterHalfIterSync, afterEndIterSync, afterEndSimSync;
		
		/* The work provider. */
		ISimWorkProvider workProvider = null;
		
		if (numWorkers == 1) {
			
			/* Setup strategies and synchronizers for single threaded execution. */
			afterInitSync =  new NoSynchronizer(SimEvent.AFTER_INIT);
			afterHalfIterSync = new NoSynchronizer(SimEvent.AFTER_HALF_ITERATION);
			afterEndIterSync = new NoSynchronizer(SimEvent.AFTER_END_ITERATION);
			afterEndSimSync = new NoSynchronizer(SimEvent.AFTER_END_SIMULATION);
			putAgentStrategy = new CellPutAgentAsync();
			
		} else {
			
			/* Setup strategies and synchronizers for multi threaded execution. */
			switch (workType) {
				case EQUAL:
					afterInitSync =  new NoSynchronizer(SimEvent.AFTER_INIT);
					afterHalfIterSync = new BlockingSynchronizer(SimEvent.AFTER_HALF_ITERATION, numWorkers);
					afterEndIterSync = new BlockingSynchronizer(SimEvent.AFTER_END_ITERATION, numWorkers);
					afterEndSimSync = new BlockingSynchronizer(SimEvent.AFTER_END_SIMULATION, numWorkers);
					putAgentStrategy = new CellPutAgentSync();
					break;
				case EQUAL_REPEAT:
					afterInitSync =  new NoSynchronizer(SimEvent.AFTER_INIT);
					afterHalfIterSync = new BlockingSynchronizer(SimEvent.AFTER_HALF_ITERATION, numWorkers);
					afterEndIterSync = new BlockingSynchronizer(SimEvent.AFTER_END_ITERATION, numWorkers);
					afterEndSimSync = new BlockingSynchronizer(SimEvent.AFTER_END_SIMULATION, numWorkers);
					putAgentStrategy = new CellPutAgentSyncSort();
					break;
				case ON_DEMAND:
					afterInitSync =  new BlockingSynchronizer(SimEvent.AFTER_INIT, numWorkers);
					afterHalfIterSync = new BlockingSynchronizer(SimEvent.AFTER_HALF_ITERATION, numWorkers);
					afterEndIterSync = new BlockingSynchronizer(SimEvent.AFTER_END_ITERATION, numWorkers);
					afterEndSimSync = new BlockingSynchronizer(SimEvent.AFTER_END_SIMULATION, numWorkers);
					putAgentStrategy = new CellPutAgentSync();
					break;
				default:
					throw new RuntimeException("Unknown error.");
			}
		}
			
		switch (workType) {
			case EQUAL:
				workProvider = new EqualSimWorkProvider(space, params.getGrassRestart(), grassInitStrategy, 
						putAgentStrategy, numWorkers, afterInitSync, afterHalfIterSync, afterEndIterSync, 
						afterEndSimSync);
				break;
			case EQUAL_REPEAT:
				workProvider = new EqualSimWorkProvider(space, params.getGrassRestart(), grassInitStrategy, 
						putAgentStrategy, numWorkers, afterInitSync, afterHalfIterSync, afterEndIterSync, 
						afterEndSimSync);
				break;
			case ON_DEMAND:
				workProvider = new OnDemandSimWorkProvider(blockSize, space, params.getGrassRestart(), grassInitStrategy, 
						putAgentStrategy, numWorkers, afterInitSync, afterHalfIterSync, afterEndIterSync, 
						afterEndSimSync);
				break;
					
			default:
				throw new RuntimeException("Unknown error.");
		}
			
		return workProvider;

	}
}