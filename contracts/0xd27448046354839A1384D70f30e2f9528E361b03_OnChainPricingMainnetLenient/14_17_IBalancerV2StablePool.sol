// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

interface IBalancerV2StablePool {
    function getAmplificationParameter() external view returns (uint256 value, bool isUpdating, uint256 precision);
    function getSwapFeePercentage() external view returns (uint256);
}