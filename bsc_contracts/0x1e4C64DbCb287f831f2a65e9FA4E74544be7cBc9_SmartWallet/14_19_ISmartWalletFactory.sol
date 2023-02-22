// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface ISmartWalletFactory {
    function getSmartWallet(address) external view returns (address);

    function isWhitelisted(address) external returns (bool);

    function dailyWithdrawLimit() external view returns (uint256);
}