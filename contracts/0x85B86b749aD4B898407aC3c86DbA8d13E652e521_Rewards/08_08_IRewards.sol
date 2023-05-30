// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface IRewards {
    function registerUserAction(address user) external;
}