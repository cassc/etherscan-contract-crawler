// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

pragma experimental ABIEncoderV2;

interface IBalancerPool {
	function getPoolId() external returns (bytes32);
}