// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILpDepositor {
    function deposit(
        address pool,
        uint256 amount,
        address[] calldata rewardTokens
    ) external;

    function withdraw(address pool, uint256 amount)
        external;

    function poke(
        address pool,
        address[] memory tokens,
        address bountyReceiver
    ) external;

    function userBalances(
        address user,
        address pool
    ) external view returns (uint256);

    function multiRewarder() external view returns (address);
}