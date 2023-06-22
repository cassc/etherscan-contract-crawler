// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title A pool-based staking contract for the Neo Tokyo ecosystem.
	@author Tim Clancy <@_Enoch>
	@author Rostislav Khlebnikov <@catpic5buck>

	This is the interface for the staker contract.

	@custom:date February 14th, 2023.
*/
interface IStaker {

	/**
		Determine the reward, based on staking participation at this moment, of a 
		particular recipient. Due to a historic web of Neo Tokyo dependencies, 
		rewards are actually minted through the BYTES contract.

		@param _recipient The recipient to calculate the reward for.

		@return A tuple containing (the number of tokens due to be minted to 
			`_recipient` as a reward, and the number of tokens that should be minted 
			to the DAO treasury as a DAO tax).
	*/
  function claimReward (
		address _recipient
	) external returns (uint256, uint256);
}