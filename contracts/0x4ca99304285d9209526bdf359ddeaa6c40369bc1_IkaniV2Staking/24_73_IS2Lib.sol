// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { SafeCastUpgradeable } from "../../../deps/oz_cu_4_7_2/SafeCastUpgradeable.sol";

import { IIkaniV2 } from "../../../nft/v2/interfaces/IIkaniV2.sol";
import { IIkaniV2Staking } from "../interfaces/IIkaniV2Staking.sol";
import { MinHeap } from "../lib/MinHeap.sol";

library IS2Lib {
    using MinHeap for MinHeap.Heap;
    using SafeCastUpgradeable for uint256;

    //---------------- External Functions ----------------//

    /**
     * @dev Settle rewards to current timestamp, returning updated context and new rewards.
     *
     *  After calling this function, the returned updated context should be saved to storage.
     *  The new rewards should also be saved to storage (or spent).
     */
    function settleAccountAndGetOwedRewards(
        IIkaniV2Staking.SettlementContext memory intialContext,
        mapping(uint256 => IIkaniV2Staking.RateChange) storage _rate_changes_,
        MinHeap.Heap storage _checkpoints_,
        mapping(uint256 => IIkaniV2Staking.TokenStakingState) storage _token_staking_state_,
        uint256 globalNumRateChanges
    )
        external
        returns (
            IIkaniV2Staking.SettlementContext memory context,
            uint256 newRewards
        )
    {
        context = intialContext;
        newRewards = 0;
    }

    function stakeLogic(
        IIkaniV2Staking.SettlementContext memory intialContext,
        IIkaniV2.PoemTraits memory traits,
        uint256 stakingStartTimestamp,
        uint256 stakedNonce,
        uint256 tokenId
    )
        external
        view
        returns (
            IIkaniV2Staking.SettlementContext memory context,
            IIkaniV2Staking.Checkpoint memory checkpoint
        )
    {
        context = intialContext;
    }

    function unstakeLogic(
        IIkaniV2Staking.SettlementContext memory intialContext,
        IIkaniV2.PoemTraits memory traits,
        uint256 stakedTimestamp
    )
        external
        view
        returns (
            IIkaniV2Staking.SettlementContext memory context
        )
    {
        context = intialContext;
    }

    //---------------- Public State-Changing Functions ----------------//

    function _insertCheckpoint(
        MinHeap.Heap storage _checkpoints_,
        IIkaniV2Staking.Checkpoint memory checkpoint
    )
        public
    {
        uint256 checkpointUint = (
            (uint256(checkpoint.timestamp) << 224) +
            (uint256(checkpoint.level) << 192) +
            (uint256(checkpoint.basePoints) << 160) +
            (uint256(checkpoint.stakedNonce) << 128) +
            checkpoint.tokenId
        );
        _checkpoints_.insert(checkpointUint);
    }

    //---------------- Public Pure Functions ----------------//

    function getFoilRewardsMultiplier(
        IIkaniV2.PoemTraits memory traits
    )
        public
        pure
        returns (uint256)
    {
        return 0;
    }

    function getStakedDurationRewardsMultiplier(
        uint256 stakedDuration
    )
        public
        pure
        returns (uint256)
    {
        return 0;
    }

    function getAccountRewardsMultiplier(
        IIkaniV2Staking.SettlementContext memory context
    )
        public
        pure
        returns (uint256)
    {
        return 0;
    }

    function getFabricsRewardsMultiplier(
        IIkaniV2Staking.SettlementContext memory context
    )
        public
        pure
        returns (uint256)
    {
        return 0;
    }

    function getSeasonsRewardsMultiplier(
        IIkaniV2Staking.SettlementContext memory context
    )
        public
        pure
        returns (uint256)
    {
        return 0;
    }

    function getNumFabricsStaked(
        IIkaniV2Staking.SettlementContext memory context
    )
        public
        pure
        returns (uint256)
    {
        return 0;
    }

    function getNumSeasonsStaked(
        IIkaniV2Staking.SettlementContext memory context
    )
        public
        pure
        returns (uint256)
    {
        return 0;
    }

    function getLevelForStakedDuration(
        uint256 stakedDuration
    )
        public
        pure
        returns (uint256)
    {
        return 0;
    }
}