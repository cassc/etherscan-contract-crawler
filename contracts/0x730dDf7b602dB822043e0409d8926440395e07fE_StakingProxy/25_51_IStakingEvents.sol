/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020 Rigo Intl.

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

pragma solidity >=0.5.9 <0.8.0;


interface IStakingEvents {

    /// @dev Emitted by MixinStake when GRG is staked.
    /// @param staker of GRG.
    /// @param amount of GRG staked.
    event Stake(
        address indexed staker,
        uint256 amount
    );

    /// @dev Emitted by MixinStake when GRG is unstaked.
    /// @param staker of GRG.
    /// @param amount of GRG unstaked.
    event Unstake(
        address indexed staker,
        uint256 amount
    );

    /// @dev Emitted by MixinStake when GRG is unstaked.
    /// @param staker of GRG.
    /// @param amount of GRG unstaked.
    event MoveStake(
        address indexed staker,
        uint256 amount,
        uint8 fromStatus,
        bytes32 indexed fromPool,
        uint8 toStatus,
        bytes32 indexed toPool
    );

    /// @dev Emitted by MixinExchangeManager when an exchange is added.
    /// @param exchangeAddress Address of new exchange.
    event PopAdded(
        address exchangeAddress
    );

    /// @dev Emitted by MixinExchangeManager when an exchange is removed.
    /// @param exchangeAddress Address of removed exchange.
    event PopRemoved(
        address exchangeAddress
    );

    /// @dev Emitted by MixinExchangeFees when a pool starts earning rewards in an epoch.
    /// @param epoch The epoch in which the pool earned rewards.
    /// @param poolId The ID of the pool.
    event StakingPoolEarnedRewardsInEpoch(
        uint256 indexed epoch,
        bytes32 indexed poolId
    );

    /// @dev Emitted by MixinFinalizer when an epoch has ended.
    /// @param epoch The epoch that ended.
    /// @param numPoolsToFinalize Number of pools that earned rewards during `epoch` and must be finalized.
    /// @param rewardsAvailable Rewards available to all pools that earned rewards during `epoch`.
    /// @param totalWeightedStake Total weighted stake across all pools that earned rewards during `epoch`.
    /// @param totalFeesCollected Total fees collected across all pools that earned rewards during `epoch`.
    event EpochEnded(
        uint256 indexed epoch,
        uint256 numPoolsToFinalize,
        uint256 rewardsAvailable,
        uint256 totalFeesCollected,
        uint256 totalWeightedStake
    );

    /// @dev Emitted by MixinFinalizer when an epoch is fully finalized.
    /// @param epoch The epoch being finalized.
    /// @param rewardsPaid Total amount of rewards paid out.
    /// @param rewardsRemaining Rewards left over.
    event EpochFinalized(
        uint256 indexed epoch,
        uint256 rewardsPaid,
        uint256 rewardsRemaining
    );

    /// @dev Emitted by MixinFinalizer when rewards are paid out to a pool.
    /// @param epoch The epoch when the rewards were paid out.
    /// @param poolId The pool's ID.
    /// @param operatorReward Amount of reward paid to pool operator.
    /// @param membersReward Amount of reward paid to pool members.
    event RewardsPaid(
        uint256 indexed epoch,
        bytes32 indexed poolId,
        uint256 operatorReward,
        uint256 membersReward
    );

    /// @dev Emitted whenever staking parameters are changed via the `setParams()` function.
    /// @param epochDurationInSeconds Minimum seconds between epochs.
    /// @param rewardDelegatedStakeWeight How much delegated stake is weighted vs operator stake, in ppm.
    /// @param minimumPoolStake Minimum amount of stake required in a pool to collect rewards.
    /// @param cobbDouglasAlphaNumerator Numerator for cobb douglas alpha factor.
    /// @param cobbDouglasAlphaDenominator Denominator for cobb douglas alpha factor.
    event ParamsSet(
        uint256 epochDurationInSeconds,
        uint32 rewardDelegatedStakeWeight,
        uint256 minimumPoolStake,
        uint256 cobbDouglasAlphaNumerator,
        uint256 cobbDouglasAlphaDenominator
    );

    /// @dev Emitted by MixinStakingPool when a new pool is created.
    /// @param poolId Unique id generated for pool.
    /// @param operator The operator (creator) of pool.
    /// @param operatorShare The share of rewards given to the operator, in ppm.
    event StakingPoolCreated(
        bytes32 poolId,
        address operator,
        uint32 operatorShare
    );

    /// @dev Emitted by MixinStakingPool when a rigoblock pool is added to its staking pool.
    /// @param rbPoolAddress Adress of maker added to pool.
    /// @param poolId Unique id of pool.
    event RbPoolStakingPoolSet(
        address indexed rbPoolAddress,
        bytes32 indexed poolId
    );

    /// @dev Emitted when a staking pool's operator share is decreased.
    /// @param poolId Unique Id of pool.
    /// @param oldOperatorShare Previous share of rewards owned by operator.
    /// @param newOperatorShare Newly decreased share of rewards owned by operator.
    event OperatorShareDecreased(
        bytes32 indexed poolId,
        uint32 oldOperatorShare,
        uint32 newOperatorShare
    );
    
    /// @dev Emitted when an inflation mint call is executed successfully.
    /// @param grgAmount Amount of GRG tokens minted to the staking proxy.
    event GrgMintEvent(uint256 grgAmount);
    
    /// @dev Emitted whenever an inflation mint call is reverted.
    /// @param reason String of the revert message.
    event CatchStringEvent(string reason);
    
    /// @dev Emitted to catch any other inflation mint call fail.
    /// @param reason Bytes output of the reverted transaction.
    event ReturnDataEvent(bytes reason);
}