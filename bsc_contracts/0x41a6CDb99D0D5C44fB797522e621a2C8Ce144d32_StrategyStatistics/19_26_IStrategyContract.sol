// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IStrategyContract {
    function releaseToken(uint256 amount, address token) external;
}

interface IStrategyVenus {
    function farmingPair() external view returns (address);

    function lendToken() external;

    function build(uint256 usdAmount) external;

    function destroy(uint256 percentage) external;

    function claimRewards(uint8 mode) external;
}