// SPDX-License-Identifier: UNLICENSED
// Created by DegenLabs https://bondswap.org

pragma solidity ^0.8.15;

interface IRegistry {
	function register(
		address _token,
		uint256 _version,
		address _creator,
		address _bondContract,
		bytes calldata _optionalData
	) external;

	function symbolNumber() external returns (uint256);
}