// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.6;

interface ISeniorRateModel {
    function getRates(uint256 juniorLiquidity, uint256 seniorLiquidity) external view returns (uint256, uint256);
    function getUpsideExposureRate(uint256 juniorLiquidity, uint256 seniorLiquidity) external view returns (uint256);
    function getDownsideProtectionRate(uint256 juniorLiquidity, uint256 seniorLiquidity) external view returns (uint256);
}