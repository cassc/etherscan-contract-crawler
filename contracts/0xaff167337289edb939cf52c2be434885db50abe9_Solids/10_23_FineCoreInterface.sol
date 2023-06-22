// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

interface FineCoreInterface {
    function getProjectAddress(uint id) external view returns (address);
    function getRandomness(uint256 id, uint256 seed) external view returns (uint256 randomnesss);
    function getProjectID(address project) external view returns (uint);
    function FINE_TREASURY() external returns (address payable);
    function platformPercentage() external returns (uint256);
    function platformRoyalty() external returns (uint256);
}