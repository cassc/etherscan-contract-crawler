// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title IIkaniV2Staking
 * @author Cyborg Labs, LLC
 *
 * @notice Interface for the IIkaniV2Staking features of the IkaniV1 ERC-721 NFT contract.
 */
interface IIkaniV2Staking {

    //---------------- Structs ----------------//

    struct RateChange {
        uint32 baseRate;
        uint32 timestamp;
    }

    struct SettlementContext {
        // The timestamp of the last settlement of this account.
        uint32 timestamp;
        // The number of global rate changes taken into account as of the last settlement
        // of this account.
        uint32 numRateChanges;
        // The global base earning rate.
        uint32 baseRate;
        // The current number of points for the account's staked tokens.
        uint32 points;
        // Current multiplier derived from the account's staked traits.
        uint32 multiplier;
        // The trait counts for the account's staked tokens.
        uint8 fabricKoyamaki;
        uint8 fabricSeigaiha;
        uint8 fabricNami;
        uint8 fabricKumo;
        uint8 fabricTba5;
        uint8 fabricTba6;
        uint8 fabricTba7;
        uint8 fabricTba8;
        uint8 seasonSpring;
        uint8 seasonSummer;
        uint8 seasonAutumn;
        uint8 seasonWinter;
    }

    struct Checkpoint {
        uint128 tokenId;
        uint32 stakedNonce;
        uint32 basePoints;
        uint32 level;
        uint32 timestamp;
    }

    struct TokenStakingState {
        uint32 timestamp;
        uint32 nonce;
    }

    //---------------- Events ----------------//

    event SetBaseRate(
        uint256 baseRate
    );

    event AdminUnstaked(
        address indexed owner,
        uint256[] indexed tokenIds,
        bytes32 indexed receipt,
        bytes receiptData
    );

    event Staked(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 stakingStartTimestamp
    );

    event Unstaked(
        address indexed owner,
        uint256 indexed tokenId
    );

    event ClaimedRewards(
        address indexed owner,
        uint256 amount
    );

    //---------------- Functions ----------------//

    function isStaked(
        uint256 tokenId
    )
        external
        view
        returns (bool);
}