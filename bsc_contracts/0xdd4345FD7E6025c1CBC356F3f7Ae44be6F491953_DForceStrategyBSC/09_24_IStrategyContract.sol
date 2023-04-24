// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IStrategyVenus {
    function farmingPair() external view returns (address);

    function lendToken() external;

    function build(uint256 usdAmount) external;

    function destroy(uint256 percentage) external;

    function claimRewards(uint8 mode) external;
}

interface IStrategy {
    function releaseToken(uint256 amount, address token) external; // onlyMultiLogicProxy

    function logic() external view returns (address);

    function useToken() external; // Automation

    function rebalance() external; // Automation

    function checkUseToken() external view returns (bool); // Automation

    function checkRebalance() external view returns (bool); // Automation

    function destroyAll() external; // onlyOwnerAdmin

    function claimRewards() external; // onlyOwnerAdmin
}