// SPDX-License-Identifier: MIT

pragma solidity =0.8.6;

interface IStakingDelegate {

    function balanceChanged(address user, uint256 amount) external;
}