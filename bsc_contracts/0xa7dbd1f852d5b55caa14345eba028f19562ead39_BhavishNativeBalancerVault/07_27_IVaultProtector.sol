// SPDX-License-Identifier: BSD-4-Clause

pragma solidity ^0.8.13;

interface IVaultProtector {
    function getMaxPredictAmount(
        uint256 vaultBalance,
        uint256 predictionPerc,
        uint256 minPredictionPerc,
        uint256 roundDownPredictAmount,
        uint256 roundUpPredictAmount,
        uint256 predictedAmount,
        bool nextPredictionUp
    ) external view returns (uint256 maxAmount);
}