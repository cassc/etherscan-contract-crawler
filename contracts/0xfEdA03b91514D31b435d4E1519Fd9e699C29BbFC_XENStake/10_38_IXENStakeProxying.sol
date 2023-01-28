// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IXENStakeProxying {
    function callStake(uint256 amount, uint256 term) external;

    function callTransfer(address to) external;

    function callWithdraw() external;

    function powerDown() external;
}