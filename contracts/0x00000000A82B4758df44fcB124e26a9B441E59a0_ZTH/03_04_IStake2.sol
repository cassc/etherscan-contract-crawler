// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IStake2 {
    function onDeposited(address user, uint256 amount) external;
    function onWithdrawn(address user, uint256 amount) external;
}