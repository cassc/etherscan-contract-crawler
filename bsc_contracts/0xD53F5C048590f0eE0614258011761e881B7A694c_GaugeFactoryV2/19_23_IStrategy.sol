// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// For interacting with our own strategy
interface IStrategy {
    // Total want tokens managed by strategy
    function balanceOf() external view returns (uint256);

    // balance of want tokens on strategy contract
    function balanceOfWant() external view returns (uint256);

    // Total staked want tokens managed by strategy
    function balanceOfStakedWant() external view returns (uint256);

    // Main want token compounding function
    function earn() external;

    // run deposit after transfering tokens
    function deposit() external;

    // Transfer want tokens strategy -> gauge
    function withdraw(uint256 _wantAmt) external;

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) external;
}