// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { IMinterModule } from "@core/interfaces/IMinterModule.sol";

/**
 * @dev Data unique to a edition max mint.
 */
struct MintData {
    // The contract to redeem tokens from
    address redemptionContract;
    // The number of unique tokens required to burn to redeem album
    uint32 requiredRedemptions;
    // The maximum number of tokens that a wallet can mint.
    uint32 maxMintablePerAccount;
}

/**
 * @dev All the information about a edition max mint (combines EditionMintData with BaseData).
 */
struct MintInfo {
    uint32 startTime;
    uint32 endTime;
    // uint16 affiliateFeeBPS;
    bool mintPaused;
    // uint96 price;
    uint32 maxMintablePerAccount;
    address redemptionContract;
    uint32 requiredRedemptions;
    uint32 maxMintableLower;
    uint32 maxMintableUpper;
    uint32 cutoffTime;
}

/**
 * @title IEditionMaxMinter
 * @dev Interface for the `EditionMaxMinter` module.
 * @author Sound.xyz
 */
interface IRedemptionMinter is IMinterModule {
    // =============================================================
    //                            EVENTS
    // =============================================================

    /**
     * @dev Emitted when a album redemption mint is created
     * @param edition               Address of the song edition contract we are minting for.
     * @param mintId                The mint ID.
     * @param requiredRedemptions   Sale price in ETH for minting a single token in `edition`.
     * @param startTime             Start timestamp of sale (in seconds since unix epoch).
     * @param endTime               End timestamp of sale (in seconds since unix epoch).
     * @param maxMintablePerAccount The maximum number of tokens that can be minted per account.
     */
    event RedemptionMintCreated(
        address indexed edition,
        uint128 indexed mintId,
        address redemptionContract,
        uint32 requiredRedemptions,
        uint32 startTime,
        uint32 endTime,
        uint32 maxMintablePerAccount
    );


    /**
     * @dev Emitted when the `maxMintablePerAccount` is changed for (`edition`, `mintId`).
     * @param edition               Address of the song edition contract we are minting for.
     * @param mintId                The mint ID.
     * @param maxMintablePerAccount The maximum number of tokens that can be minted per account.
     */
    event MaxMintablePerAccountSet(address indexed edition, uint128 indexed mintId, uint32 maxMintablePerAccount);

    // =============================================================
    //                            ERRORS
    // =============================================================

    /**
     * @dev The number of tokens minted has exceeded the number allowed for each account.
     */
    error ExceedsMaxPerAccount();


    /**
     * @dev The token offered for redemption is not owned by message sender
     */
    error OfferedTokenNotOwned();

    /**
     * @dev The array of tokens is not the right length
     */
    error InvalidNumberOfTokensOffered();

    /**
     * @dev The max mintable per account cannot be zero.
     */
    error MaxMintablePerAccountIsZero();

    // =============================================================
    //               PUBLIC / EXTERNAL WRITE FUNCTIONS
    // =============================================================

    /*
     * @dev Initializes a range mint instance
     * @param songEdition           Address of the song edition contract we are redeeming from
     * @param secretEdition          Address of the album edition contract we are minting for.
     * @param startTime             Start timestamp of sale (in seconds since unix epoch).
     * @param endTime               End timestamp of sale (in seconds since unix epoch).
     * @param requiredRedemptions   Amount of unique tokens to burn for album.
     * @param maxMintablePerAccount The maximum number of tokens that can be minted by an account.
     * @return mintId The ID for the new mint instance.
     */
    function createRedemptionMint(
        address songEdition,
        address secretEdition,
        uint32 startTime,
        uint32 endTime,
        uint32 requiredRedemptions,
        uint32 maxMintablePerAccount
    ) external returns (uint128 mintId);

    /*
     * @dev Mints tokens for a given edition.
     * @param edition   Address of the song edition contract we are minting for.
     * @param mintId    The mint ID.
     * @param quantity  Token quantity to mint in song `edition`.
     * @param tokenIds  Tokens to redeem, ordered by shuffled token ID
     */
    function mint(
        address edition,
        uint128 mintId,
        uint256[] calldata tokenIds
    ) external;


    /*
     * @dev Sets the `maxMintablePerAccount` for (`edition`, `mintId`).
     * @param edition               Address of the song edition contract we are minting for.
     * @param mintId                The mint ID.
     * @param maxMintablePerAccount The maximum number of tokens that can be minted by an account.
     */
    function setMaxMintablePerAccount(
        address edition,
        uint128 mintId,
        uint32 maxMintablePerAccount
    ) external;

    // =============================================================
    //               PUBLIC / EXTERNAL VIEW FUNCTIONS
    // =============================================================

    /**
     * @dev Returns {IEditionMaxMinter.MintInfo} instance containing the full minter parameter set.
     * @param edition The edition to get the mint instance for.
     * @param mintId  The ID of the mint instance.
     * @return mintInfo Information about this mint.
     */
    function mintInfo(address edition, uint128 mintId) external view returns (MintInfo memory);
}