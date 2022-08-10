// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBaseRewardPool {
    function balanceOf(address _account) external view returns (uint256);

    function withdraw(uint256 _amount, bool _claim) external returns (bool);

    function withdrawAndUnwrap(uint256 _amount, bool _claim)
        external
        returns (bool);

    function getReward() external returns (bool);

    function stake(uint256 _amount) external returns (bool);

    function stakeFor(address _account, uint256 _amount)
        external
        returns (bool);
}