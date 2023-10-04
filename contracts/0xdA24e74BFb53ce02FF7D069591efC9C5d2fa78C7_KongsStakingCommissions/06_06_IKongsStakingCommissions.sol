// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Kongs Staking Commissions Interface v1.0
 * @author DeployLabs.io
 *
 * @notice This in an interface for the Kongs Staking Comission contract.
 */
interface IKongsStakingCommissions {
	event CommissionPaid(uint256 indexed uuid, address indexed payer, uint256 amount);

	error KongsStaking__NothingToWithdraw();
	error KongsStaking__ZeroAddressProhibited();

	/**
	 * @notice Pay the commission for staking a Kong.
	 * @param uuid The UUID of the payment.
	 */
	function payCommission(uint256 uuid) external payable;

	/**
	 * @notice Withdraw the contract balance.
	 * @param to The address to withdraw to.
	 */
	function withdraw(address payable to) external;
}