// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRandomizer {
    function randomize() external returns (uint256);

    function randomize(uint256 limit) external returns (uint256);

    function distributeRandom(uint256 total, uint256[] memory weights)
        external
        returns (uint256);

    function last() external view returns (uint256);
}