// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IBigexInterface {
	function getITransferInvestment(address account) external view returns (uint256);
	function getITransferAidrop(address account) external view returns (uint256);
}