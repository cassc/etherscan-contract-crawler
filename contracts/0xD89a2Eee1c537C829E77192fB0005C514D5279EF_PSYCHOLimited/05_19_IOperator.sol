// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

interface IOperator {
	event OperatorshipTransferred(address indexed _from, address indexed _to);

	function operator() external view returns (address);

	function transferOperatorship(address _to) external;
}