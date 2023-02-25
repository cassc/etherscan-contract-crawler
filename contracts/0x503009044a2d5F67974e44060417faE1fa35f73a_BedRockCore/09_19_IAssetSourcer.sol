// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IAssetSourcer {
    function initialize() external;

    function onDeposit(address token, uint256 amount) external;

    function onWithdraw(address token, uint256 amount) external;
}