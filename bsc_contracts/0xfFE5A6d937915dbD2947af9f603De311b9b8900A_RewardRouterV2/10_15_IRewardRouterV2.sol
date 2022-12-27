// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IRewardRouterV2 {
    function feeSlpTracker() external view returns (address);

    function stakedSlpTracker() external view returns (address);
}