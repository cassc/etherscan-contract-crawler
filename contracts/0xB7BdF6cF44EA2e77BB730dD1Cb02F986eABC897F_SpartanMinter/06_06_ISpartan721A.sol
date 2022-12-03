// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/// @dev This is an interface whereby we can interact with the base ERC20 contract
interface ISpartan721A {
    function totalSupply() external returns(uint256);
    function maxId() external returns(uint256);
    function mintsPerUser(address user) external returns(uint256);
    function mintingLimit() external returns(uint256);
    function mintId(bytes16 mintId_) external returns (bool);
    function adminMint(address user, uint256 amount) external;

}