// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.9;

interface RocketDAOProtocolSettingsDepositInterface {
    function getDepositEnabled() external view returns (bool);
    function getMaximumDepositPoolSize() external view returns (uint256);
    function getMinimumDeposit() external view returns (uint256);
}