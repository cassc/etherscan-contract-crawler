// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

interface IStaking {
    function stake(address _to, uint256 _amount) external;

    function unstake(address _to, uint256 _amount, bool _rebase) external;

    function rebase() external;

    function index() external view returns (uint256);
}