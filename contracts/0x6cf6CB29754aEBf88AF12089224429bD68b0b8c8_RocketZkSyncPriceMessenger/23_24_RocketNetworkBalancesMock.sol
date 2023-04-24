// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

/// @author Kane Wallmann (Rocket Pool)
/// @notice Mocks just the required functions of RocketNetworkBalances
contract RocketNetworkBalancesMock {
    uint256 totalETHBalance;
    uint256 totalRETHSupply;

    function setTotalETHBalance(uint256 _value) external {
        totalETHBalance = _value;
    }

    function getTotalETHBalance() external view returns (uint256) {
        return totalETHBalance;
    }

    function setTotalRETHSupply(uint256 _value) external {
        totalRETHSupply = _value;
    }

    function getTotalRETHSupply() external view returns (uint256) {
        return totalRETHSupply;
    }
}