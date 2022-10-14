// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

interface ILiquidityGauge {
    function admin() external view returns (address _addr);

    function balanceOf(address _addr) external view returns (uint256 amount);

    function totalSupply() external view returns (uint256 amount);

    function staking_token() external view returns (address stakingToken);

    function deposit_reward_token(address _rewardToken, uint256 _amount) external;

    function deposit(
        uint256 _value,
        address _addr,
        // solhint-disable-next-line
        bool _claim_rewards
    ) external;

    function claim_rewards(address _addr) external;

    function claim_rewards(address _addr, address _receiver) external;

    function commit_transfer_ownership(address _addr) external;

    function accept_transfer_ownership() external;

    function name() external view returns (string memory name);
}