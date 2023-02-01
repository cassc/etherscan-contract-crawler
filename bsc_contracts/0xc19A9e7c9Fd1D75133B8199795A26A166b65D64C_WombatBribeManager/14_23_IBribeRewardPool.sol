// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IBaseRewardPool.sol";

interface IBribeRewardPool is IBaseRewardPool {
    function balanceOf(address _account) external view returns (uint256);

    function stakeFor(address _for, uint256 _amount) external;

    function withdrawFor(address _for, uint256 _amount, bool claim) external;
}