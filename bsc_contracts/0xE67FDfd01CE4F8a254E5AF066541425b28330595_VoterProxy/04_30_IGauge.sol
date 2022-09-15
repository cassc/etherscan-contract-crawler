// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IGauge {
    function rewardTokens(uint256) external returns (address);

    function rewardTokensLength() external view returns (uint256);

    function earned(address, address) external view returns (uint256);

    function getReward(address account, address[] memory tokens) external;
}