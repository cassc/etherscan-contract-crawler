// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { AddressUpgradeable } from "../../../deps/oz_cu_4_7_2/AddressUpgradeable.sol";
import { IERC721Upgradeable } from "../../../deps/oz_cu_4_7_2/IERC721Upgradeable.sol";
import { SafeCastUpgradeable } from "../../../deps/oz_cu_4_7_2/SafeCastUpgradeable.sol";

import { IIkaniV2 } from "../../../nft/v2/interfaces/IIkaniV2.sol";

import { IS2Lib } from "../lib/IS2Lib.sol";
import { MinHeap } from "../lib/MinHeap.sol";
import { IS2Erc20 } from "./IS2Erc20.sol";

/**
 * @title IS2Core
 * @author Cyborg Labs, LLC
 */
abstract contract IS2Core is
    IS2Erc20
{
    using SafeCastUpgradeable for uint256;

    //---------------- External Functions ----------------//

    /**
     * @notice Stake one or more tokens owned by a single owner.
     *
     *  Will revert if any of the tokens are already staked.
     *  Will revert if the same token is included more than once.
     */
    function stake(
        address owner,
        uint256[] calldata tokenIds
    )
        external
        whenNotPaused
    {
        // Verify owner and authorization.
        _requireSameOwnerAndAuthorized(owner, tokenIds, false);

        // Get the updated rewards context and new rewards.
        (SettlementContext memory context, uint256 rewardsDiff) = _settleAccount(owner);

        // Stake the tokens.
        context = _stake(context, owner, tokenIds, new uint256[](0));

        // Update storage for the account.
        _SETTLEMENT_CONTEXT_[owner] = context;
        if (rewardsDiff != 0) {
            _REWARDS_[owner] += rewardsDiff;
        }
    }

    function unstake(
        address owner,
        uint256[] calldata tokenIds
    )
        external
        whenNotPaused
    {
        // Verify owner and authorization.
        _requireSameOwnerAndAuthorized(owner, tokenIds, false);

        // Get the updated rewards context and new rewards.
        (SettlementContext memory context, uint256 rewardsDiff) = _settleAccount(owner);

        // Unstake the tokens.
        context = _unstake(context, owner, tokenIds);

        // Update storage for the account.
        _SETTLEMENT_CONTEXT_[owner] = context;
        _REWARDS_[owner] += rewardsDiff;
    }

    function batchSafeTransferFromStaked(
        address owner,
        address recipient,
        uint256[] calldata tokenIds
    )
        external
        whenNotPaused
    {
        require(
            msg.sender == owner,
            "Only owner can transfer staked"
        );

        // Verify owner.
        _requireSameOwnerAndAuthorized(owner, tokenIds, true);

        // Get the updated rewards context and new rewards.
        (
            SettlementContext memory ownerContext,
            uint256 ownerRewardsDiff
        ) = _settleAccount(owner);
        (
            SettlementContext memory recipientContext,
            uint256 recipientRewardsDiff
        ) = _settleAccount(recipient);

        // Get the staked timestamps.
        uint256 n = tokenIds.length;
        uint256[] memory stakedTimestamps = new uint256[](n);
        for (uint256 i = 0; i < n;) {
            stakedTimestamps[i] = _TOKEN_STAKING_STATE_[tokenIds[i]].timestamp;
            unchecked { ++i; }
        }

        // Unstake and restake the tokens.
        ownerContext = _unstake(ownerContext, owner, tokenIds);
        recipientContext = _stake(recipientContext, recipient, tokenIds, stakedTimestamps);

        // Update storage for the accounts.
        _SETTLEMENT_CONTEXT_[owner] = ownerContext;
        _REWARDS_[owner] += ownerRewardsDiff;
        _SETTLEMENT_CONTEXT_[recipient] = recipientContext;
        _REWARDS_[recipient] += recipientRewardsDiff;

        // Do transfers last, since a “safe” transfer can execute arbitrary smart contract code.
        // This is important to prevent reentrancy attacks.
        for (uint256 i = 0; i < n;) {
            IERC721Upgradeable(IKANI).safeTransferFrom(owner, recipient, tokenIds[i]);
            unchecked { ++i; }
        }
    }

    /**
     * @notice Claim all rewards for the account.
     *
     *  This function can be called with eth_call (e.g. callStatic in ethers.js) to get the
     *  current unclaimed rewards balance for an account.
     */
    function claimRewards(
        address owner,
        address recipient
    )
        external
        whenNotPaused
        returns (uint256)
    {
        require(
            msg.sender == owner,
            "Sender is not owner"
        );
        return _claimRewards(owner, recipient);
    }

    function claimAndBurnRewards(
        address owner,
        uint256 burnAmount,
        bytes32 burnReceipt,
        bytes calldata burnReceiptData,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        whenNotPaused
    {
        require(
            msg.sender == owner,
            "Sender is not owner"
        );
        _claimRewards(owner, owner);
        _burnErc20(owner, burnAmount, burnReceipt, burnReceiptData, deadline, v, r, s);
    }

    /**
     * @notice Settle rewards for an account.
     *
     *  Note: There is no access control on this function.
     */
    function settleRewards(
        address owner
    )
        external
        whenNotPaused
        returns (uint256)
    {
        return _settleRewards(owner);
    }

    //---------------- Internal Functions ----------------//

    function _settleRewards(
        address owner
    )
        internal
        returns (uint256)
    {
        uint256 rewardsOld = _REWARDS_[owner];

        // Get the updated rewards context and new rewards.
        (SettlementContext memory context, uint256 rewardsDiff) = _settleAccount(owner);

        uint256 rewardsNew = rewardsOld + rewardsDiff;

        // Update storage.
        _SETTLEMENT_CONTEXT_[owner] = context;
        _REWARDS_[owner] = rewardsNew;

        return _getErc20Amount(rewardsNew);
    }

    function _claimRewards(
        address owner,
        address recipient
    )
        internal
        returns (uint256)
    {
        uint256 rewardsOld = _REWARDS_[owner];

        // Get the updated rewards context and new rewards.
        (SettlementContext memory context, uint256 rewardsDiff) = _settleAccount(owner);

        // Update storage.
        _SETTLEMENT_CONTEXT_[owner] = context;
        _REWARDS_[owner] = 0;

        // Mint the rewards amount.
        uint256 rewardsNew = rewardsOld + rewardsDiff;
        uint256 erc20Amount = _issueRewards(recipient, rewardsNew);

        emit ClaimedRewards(owner, erc20Amount);

        return erc20Amount;
    }

    function _stake(
        SettlementContext memory initialContext,
        address owner,
        uint256[] calldata tokenIds,
        uint256[] memory maybeStakingStartTimestamps
    )
        internal
        returns (SettlementContext memory context)
    {
        context = initialContext;
        uint256 n = tokenIds.length;

        for (uint256 i = 0; i < n;) {
            uint256 tokenId = tokenIds[i];

            // Get the current staking state for the token.
            TokenStakingState memory stakingState = _TOKEN_STAKING_STATE_[tokenId];

            // Require that the token is not currently staked.
            // Note that this will revert if the same token appeared twice in the list.
            require(
                stakingState.timestamp == 0,
                "Already staked"
            );

            // The timestamp to use as the staking start timestamp for the token.
            uint256 stakingStartTimestamp = maybeStakingStartTimestamps.length > 0
                ? maybeStakingStartTimestamps[i]
                : block.timestamp;

            Checkpoint memory checkpoint;
            (context, checkpoint) = IS2Lib.stakeLogic(
                context,
                IIkaniV2(IKANI).getPoemTraits(tokenId),
                stakingStartTimestamp,
                stakingState.nonce,
                tokenId
            );

            // Update storage for the token.
            if (checkpoint.timestamp != 0) {
                IS2Lib._insertCheckpoint(_CHECKPOINTS_[owner], checkpoint);
            }
            _TOKEN_STAKING_STATE_[tokenId].timestamp = stakingStartTimestamp.toUint32();

            emit Staked(owner, tokenId, stakingStartTimestamp);

            unchecked { ++i; }
        }
    }

    function _unstake(
        SettlementContext memory initialContext,
        address owner,
        uint256[] calldata tokenIds
    )
        internal
        returns (SettlementContext memory context)
    {
        context = initialContext;
        uint256 n = tokenIds.length;

        for (uint256 i = 0; i < n;) {
            uint256 tokenId = tokenIds[i];

            // Get the current staking state for the token.
            TokenStakingState memory stakingState = _TOKEN_STAKING_STATE_[tokenId];

            // Require that the token is currently staked.
            // Note that this will revert if the same token appeared twice in the list.
            require(
                stakingState.timestamp != 0,
                "Not staked"
            );

            context = IS2Lib.unstakeLogic(
                context,
                IIkaniV2(IKANI).getPoemTraits(tokenId),
                stakingState.timestamp
            );

            // Update storage for the token.
            unchecked {
                _TOKEN_STAKING_STATE_[tokenId] = TokenStakingState({
                    timestamp: 0,
                    nonce: stakingState.nonce + 1
                });
            }

            emit Unstaked(owner, tokenId);

            unchecked { ++i; }
        }
    }

    function _requireSameOwnerAndAuthorized(
        address owner,
        uint256[] calldata tokenIds,
        bool alreadyAuthorized
    )
        internal
        view
    {
        address sender = msg.sender;
        bool senderIsOwner = sender == owner;
        uint256 n = tokenIds.length;

        // Verify owner and authorization.
        for (uint256 i = 0; i < n;) {
            uint256 tokenId = tokenIds[i];

            require(
                IERC721Upgradeable(IKANI).ownerOf(tokenId) == owner,
                "Wrong owner"
            );
            require(
                alreadyAuthorized || senderIsOwner || _isApproved(sender, owner, tokenId),
                "Not authorized to stake/unstake"
            );

            unchecked { ++i; }
        }
    }

    function _settleAccount(
        address owner
    )
        internal
        returns (
            SettlementContext memory context,
            uint256 rewardsDiff
        )
    {
        (context, rewardsDiff) = IS2Lib.settleAccountAndGetOwedRewards(
            _SETTLEMENT_CONTEXT_[owner],
            _RATE_CHANGES_,
            _CHECKPOINTS_[owner],
            _TOKEN_STAKING_STATE_,
            _NUM_RATE_CHANGES_
        );
    }

    function _isApproved(
        address spender,
        address owner,
        uint256 tokenId
    )
        internal
        view
        returns (bool)
    {
        return (
            IERC721Upgradeable(IKANI).isApprovedForAll(owner, spender) ||
            IERC721Upgradeable(IKANI).getApproved(tokenId) == spender
        );
    }
}