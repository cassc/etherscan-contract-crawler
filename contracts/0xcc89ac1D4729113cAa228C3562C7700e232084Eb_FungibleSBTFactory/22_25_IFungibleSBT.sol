// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

interface IFungibleSBT {
    function mint(address to, uint256 id) external;

    function owner() external view returns (address);

    function add() external;

    function exists(uint256 id) external view returns (bool);

    function nextId() external view returns (uint256);
}