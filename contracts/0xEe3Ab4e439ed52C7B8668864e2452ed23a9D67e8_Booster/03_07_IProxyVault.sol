// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IProxyVault {

    enum VaultType{
        Erc20Baic,
        UniV3,
        Convex
    }

    function initialize(address _owner, address _stakingAddress, address _stakingToken, address _rewardsAddress) external;
    function usingProxy() external returns(address);
    function rewards() external returns(address);
    function getReward() external;
    function getReward(bool _claim) external;
    function getReward(bool _claim, address[] calldata _rewardTokenList) external;
    function earned() external view returns (address[] memory token_addresses, uint256[] memory total_earned);
}