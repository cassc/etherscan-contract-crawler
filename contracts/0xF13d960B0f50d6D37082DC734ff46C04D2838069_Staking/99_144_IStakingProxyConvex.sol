// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

// solhint-disable var-name-mixedcase
interface IStakingProxyConvex {
	//create a new locked state of _secs timelength with a Curve LP token
	function stakeLockedCurveLp(uint256 _liquidity, uint256 _secs) external returns (bytes32 kek_id);

	//withdraw a staked position
	//frax farm transfers first before updating farm state so will checkpoint during transfer
	function withdrawLockedAndUnwrap(bytes32 _kek_id) external;

	/*
    claim flow:
        claim rewards directly to the vault
        calculate fees to send to fee deposit
        send fxs to a holder contract for fees
        get reward list of tokens that were received
        send all remaining tokens to owner

    A slightly less gas intensive approach could be to send rewards directly to a holder contract and have it sort everything out.
    However that makes the logic a bit more complex as well as runs a few future proofing risks
    */
	function getReward() external;

	function curveLpToken() external returns (address);
}