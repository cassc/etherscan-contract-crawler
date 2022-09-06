// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IFeeDistributor {
	function claim() external returns (uint256);
}