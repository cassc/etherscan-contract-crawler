// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;
struct RequestedWithdrawalInfo {
    uint256 minCycle;
    uint256 amount;
}

interface ITokePool {
    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function requestWithdrawal(uint256 amount) external;

    function balanceOf(address owner) external view returns (uint256);

    function requestedWithdrawals(address owner)
        external
        returns (RequestedWithdrawalInfo memory);
}