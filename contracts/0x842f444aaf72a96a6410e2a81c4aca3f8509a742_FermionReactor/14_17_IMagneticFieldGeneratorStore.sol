// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@exoda/contracts/interfaces/access/IOwnable.sol";
import "../structs/PoolInfo.sol";
import "../structs/UserInfo.sol";

interface IMagneticFieldGeneratorStore is IOwnable
{
	function deletePoolInfo(uint256 pid) external;
	function newPoolInfo(PoolInfo memory pi) external;
	function updateUserInfo(uint256 pid, address user, UserInfo memory ui) external;
	function updatePoolInfo(uint256 pid, PoolInfo memory pi) external;
	function getPoolInfo(uint256 pid) external view returns (PoolInfo memory);
	function getPoolLength() external view returns (uint256);
	function getUserInfo(uint256 pid, address user) external view returns (UserInfo memory);
	
}