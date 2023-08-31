// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IiUSTP {
	function wrap(uint256 _amount) external;

	function unwrap(uint256 _amount) external;
}