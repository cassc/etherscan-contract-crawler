// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.10;

/**
 * @title MintManager interface for onchain abridged mint vectors
 * @author highlight.xyz
 */
interface IAbridgedMintVector {
    /**
     * @notice On-chain mint vector (stored data)
     * @param contractAddress NFT smart contract address
     * @param startTimestamp When minting opens on vector
     * @param endTimestamp When minting ends on vector
     * @param paymentRecipient Payment recipient
     * @param maxTotalClaimableViaVector Max number of tokens that can be minted via vector
     * @param totalClaimedViaVector Total number of tokens minted via vector
     * @param currency Currency used for payment. Native gas token, if zero address
     * @param tokenLimitPerTx Max number of tokens that can be minted in one transaction
     * @param maxUserClaimableViaVector Max number of tokens that can be minted by user via vector
     * @param pricePerToken Price that has to be paid per minted token
     * @param editionId Edition ID, if vector is for edition based collection
     * @param editionBasedCollection If vector is for an edition based collection
     * @param requireDirectEOA Require minters to directly be EOAs
     * @param allowlistRoot Root of merkle tree with allowlist
     */
    struct AbridgedVectorData {
        uint160 contractAddress;
        uint48 startTimestamp;
        uint48 endTimestamp;
        uint160 paymentRecipient;
        uint48 maxTotalClaimableViaVector;
        uint48 totalClaimedViaVector;
        uint160 currency;
        uint48 tokenLimitPerTx;
        uint48 maxUserClaimableViaVector;
        uint192 pricePerToken;
        uint48 editionId;
        bool editionBasedCollection;
        bool requireDirectEOA;
        bytes32 allowlistRoot;
    }

    /**
     * @notice On-chain mint vector (public) - See {AbridgedVectorData}
     */
    struct AbridgedVector {
        address contractAddress;
        uint48 startTimestamp;
        uint48 endTimestamp;
        address paymentRecipient;
        uint48 maxTotalClaimableViaVector;
        uint48 totalClaimedViaVector;
        address currency;
        uint48 tokenLimitPerTx;
        uint48 maxUserClaimableViaVector;
        uint192 pricePerToken;
        uint48 editionId;
        bool editionBasedCollection;
        bool requireDirectEOA;
        bytes32 allowlistRoot;
    }

    /**
     * @notice Config defining what fields to update
     * @param updateStartTimestamp If 1, update startTimestamp
     * @param updateEndTimestamp If 1, update endTimestamp
     * @param updatePaymentRecipient If 1, update paymentRecipient
     * @param updateMaxTotalClaimableViaVector If 1, update maxTotalClaimableViaVector
     * @param updateTokenLimitPerTx If 1, update tokenLimitPerTx
     * @param updateMaxUserClaimableViaVector If 1, update maxUserClaimableViaVector
     * @param updatePricePerToken If 1, update pricePerToken
     * @param updateAllowlistRoot If 1, update allowlistRoot
     * @param updateRequireDirectEOA If 1, update requireDirectEOA
     * @param updateMetadata If 1, update MintVector metadata
     */
    struct UpdateAbridgedVectorConfig {
        uint16 updateStartTimestamp;
        uint16 updateEndTimestamp;
        uint16 updatePaymentRecipient;
        uint16 updateMaxTotalClaimableViaVector;
        uint16 updateTokenLimitPerTx;
        uint16 updateMaxUserClaimableViaVector;
        uint8 updatePricePerToken;
        uint8 updateAllowlistRoot;
        uint8 updateRequireDirectEOA;
        uint8 updateMetadata;
    }

    /**
     * @notice Creates on-chain vector
     * @param _vector Vector to create
     */
    function createAbridgedVector(AbridgedVectorData memory _vector) external;

    /**
     * @notice Updates on-chain vector
     * @param vectorId ID of vector to update
     * @param _newVector New vector details
     * @param updateConfig Number encoding what fields to update
     * @param pause Pause / unpause vector
     * @param flexibleData Flexible data in vector metadata
     */
    function updateAbridgedVector(
        uint256 vectorId,
        AbridgedVector calldata _newVector,
        UpdateAbridgedVectorConfig calldata updateConfig,
        bool pause,
        uint128 flexibleData
    ) external;

    /**
     * @notice Deletes on-chain vector
     * @param vectorId ID of abridged vector to delete
     */
    function deleteAbridgedVector(uint256 vectorId) external;

    /**
     * @notice Pauses or unpauses an on-chain mint vector
     * @param vectorId ID of abridged vector to pause
     * @param pause True to pause, False to unpause
     * @param flexibleData Flexible data that can be interpreted differently
     */
    function setAbridgedVectorMetadata(uint256 vectorId, bool pause, uint128 flexibleData) external;

    /**
     * @notice Get on-chain abridged vector
     * @param vectorId ID of abridged vector to get
     */
    function getAbridgedVector(uint256 vectorId) external view returns (AbridgedVector memory);

    /**
     * @notice Get on-chain abridged vector metadata
     * @param vectorId ID of abridged vector to get
     */
    function getAbridgedVectorMetadata(uint256 vectorId) external view returns (bool, uint128);
}