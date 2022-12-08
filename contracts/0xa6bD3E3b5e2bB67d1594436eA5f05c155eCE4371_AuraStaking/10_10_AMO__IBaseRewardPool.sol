pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later

interface AMO__IBaseRewardPool {
    function withdrawAndUnwrap(uint256 amount, bool claim) external returns(bool);
    function withdrawAll(bool claim) external;
    function withdrawAllAndUnwrap(bool claim) external;
    function withdraw(uint256 amount, bool claim) external;
    function stakeFor(address _for, uint256 _amount) external returns(bool);
    function stakeAll() external returns(bool);
    function stake(uint256 _amount) external returns(bool);
    function earned(address account) external view returns (uint256);
    function getReward(address _account, bool _claimExtras) external returns(bool);
    function getReward() external returns(bool);
    function balanceOf(address account) external view returns (uint256) ;
    function rewardToken() external view returns (address);
}