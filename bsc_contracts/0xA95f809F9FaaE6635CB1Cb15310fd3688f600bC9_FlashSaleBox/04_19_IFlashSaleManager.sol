// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IFlashSaleManager {
    function calculateRewards(uint256 _boxId, uint256 _createdAtBlock)
        external
        returns (uint256 dinoGenes1, uint256 dinoGenes2, uint256 dinoGenes3, uint256 dinoGenes4, uint256 dinoGenes5);
}