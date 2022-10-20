// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

interface IConvexRewardsPool {
    function balanceOf(address account) external view returns (uint256);

    function currentRewards() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getReward() external returns (bool);

    function getReward(address _account, bool _claimExtras) external returns (bool);

    function rewards(address) external view returns (uint256);

    function stake(uint256 _amount) external returns (bool);

    function stakeFor(address _for, uint256 _amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function withdraw(uint256 amount, bool claim) external returns (bool);

    function withdrawAllAndUnwrap(bool claim) external;

    function withdrawAndUnwrap(uint256 amount, bool claim) external returns (bool);
}