// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title A migrated ERC-20 BYTES token contract for the Neo Tokyo ecosystem.
	@author Tim Clancy <@_Enoch>

	This is the interface for the BYTES 2.0 contract.

	@custom:date February 14th, 2023.
*/
interface IByteContract {

	/**
		Permit authorized callers to burn BYTES from the `_from` address. When 
		BYTES are burnt, 2/3 of the BYTES are sent to the DAO treasury. This 
		operation is never expected to overflow given operational bounds on the 
		amount of BYTES tokens ever allowed to enter circulation.

		@param _from The address to burn tokens from.
		@param _amount The amount of tokens to burn.
	*/
	function burn (
		address _from,
		uint256 _amount
	) external;
	
	/**
		This function is called by the S1 Citizen contract to emit BYTES to callers 
		based on their state from the staker contract.

		@param _to The reward address to mint BYTES to.
	*/
	function getReward (
		address _to
	) external;
}