// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBondCalculator {
    function computeRoi(
        uint256 timestamp,
        uint256 bondRoundStartingTime,
        uint256 totalPeriodsNumber,
        uint256 composedFunction,
        uint256 maxCvgToMint,
        uint256 cvgMintedOnActualRound,
        uint256 minRoi,
        uint256 maxRoi
    ) external pure returns (uint256);
}