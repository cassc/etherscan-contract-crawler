// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IGauge {
    function deposit(uint256) external;

    function balanceOf(address) external view returns (uint256);

    function withdraw(uint256) external;

    function claim_rewards() external;

    function reward_tokens(uint256) external view returns (address); //v2

    function rewarded_token() external view returns (address); //v1

    function getReward() external;

    function scaling_factor() external view returns (uint256);
}