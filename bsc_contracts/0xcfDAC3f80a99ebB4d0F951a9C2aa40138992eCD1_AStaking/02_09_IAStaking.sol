// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2022 Rigo Intl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity >=0.8.0 <0.9.0;

interface IAStaking {
    /// @notice Stakes an amount of GRG to own staking pool. Creates staking pool if doesn't exist.
    /// @dev Creating staking pool if doesn't exist effectively locks direct call.
    /// @param amount Amount of GRG to stake.
    function stake(uint256 amount) external;

    /// @notice Undelegates stake for the pool.
    /// @param amount Number of GRG units with undelegate.
    function undelegateStake(uint256 amount) external;

    /// @notice Unstakes staked undelegated tokens for the pool.
    /// @param amount Number of GRG units to unstake.
    function unstake(uint256 amount) external;

    /// @notice Withdraws delegator rewards of the pool.
    function withdrawDelegatorRewards() external;
}