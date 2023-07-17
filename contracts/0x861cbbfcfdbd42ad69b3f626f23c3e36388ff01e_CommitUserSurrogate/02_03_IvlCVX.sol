// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IvlCVX{
	function checkpointEpoch() external;
	function epochCount() external view returns(uint256);
	function balanceOf(address _user) view external returns(uint256 amount);
}