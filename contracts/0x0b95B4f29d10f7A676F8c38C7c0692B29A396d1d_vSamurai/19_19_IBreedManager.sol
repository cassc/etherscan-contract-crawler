// SPDX-License-Identifier: MIT
// BuildingIdeas.io (IBreedManager.sol)

pragma solidity ^0.8.11;

interface IBreedManager {
	function breed(uint256 _male, uint256 _female) external returns(bool);
	function registerGender(bytes calldata signature, uint256 _tokenId, uint256 _gender) external;
}