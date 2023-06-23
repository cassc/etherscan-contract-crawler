// SPDX-License-Identifier: MIT

// @author: Fair.xyz dev

pragma solidity 0.8.19;

import {Stage} from "../interfaces/IFairxyzMintStagesRegistry.sol";

/**
 * @param maxMintsPerWallet the maximum number of tokens that can be minted per wallet/account
 * @param maxSupply the maximum supply for the edition including paid mints and airdrops
 * @param burnable_ the burnable state of the edition
 * @param signatureReleased whether the signature is required to mint tokens for the edition
 * @param soulbound whether the edition tokens are soulbound
 */
struct Edition {
    uint40 maxMintsPerWallet;
    uint40 maxSupply;
    bool burnable;
    bool signatureReleased;
    bool soulbound;
}

/**
 * @param externalId the external ID of the edition used to identify it off-chain
 * @param edition the edition struct
 * @param uri the URI for the edition/token metadata
 * @param mintStages the mint stages for the edition
 */
struct EditionCreateParams {
    uint256 externalId;
    Edition edition;
    string uri;
    Stage[] mintStages;
}

struct EditionMinter {
    uint40 mintedCount;
    uint40 lastUsedNonce;
}

interface IFairxyzEditions {
    error EditionAlreadyMinted();
    error EditionDoesNotExist();
    error EditionSignatureAlreadyReleased();
    error EditionSupplyCanOnlyBeReduced();
    error EditionSupplyLessThanMintedCount();
    error EditionSupplyLessThanScheduledStagesPhaseLimit();
    error EditionSupplyTooLarge();
    error IncorrectEthValue();
    error InvalidMintQuantity();
    error InvalidNumberOfRecipients();
    error InvalidSignatureNonce();
    error InvalidSignature();
    error InvalidURI();
    error NotApprovedOrOwner();
    error NotBurnable();
    error NotEnoughSupplyRemaining();
    error NotTransferable();
    error RecipientAllowanceUsed();
    error RecipientEditionAllowanceUsed();
    error RecipientStageAllowanceUsed();
    error SignatureAlreadyUsed();
    error SignatureExpired();
    error StageSoldOut();
    error TokenDoesNotExist();
    error ZeroAddress();

    /// @dev Emitted when the metadata of a range of tokens is changed.
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    /// @dev Emitted when the default royalty details are changed.
    event DefaultRoyalty(address receiver, uint96 royaltyFraction);

    /// @dev Emitted when edition tokens are airdropped.
    event EditionAirdrop(
        uint256 indexed editionId,
        uint256 indexed stageIndex,
        address[] recipients,
        uint256 quantity,
        uint256 editionMintedCount
    );

    /// @dev Emitted when the burnable state of an edition is changed.
    event EditionBurnable(uint256 indexed editionId, bool burnable);

    /// @dev Emitted when a new edition is added.
    event EditionCreated(
        uint256 indexed editionId,
        uint256 externalId,
        Edition edition
    );

    /// @dev Emitted when an edition is deleted and can no longer be minted.
    event EditionDeleted(uint256 indexed editionId);

    /// @dev Emitted when the maximum mints per wallet for an edition is changed.
    event EditionMaxMintsPerWallet(
        uint256 indexed editionId,
        uint256 maxMintsPerWallet
    );

    /// @dev Emitted when the maximum supply for an edition is changed.
    event EditionMaxSupply(uint256 indexed editionId, uint256 maxSupply);

    /// @dev Emitted when the royalty details for an edition are changed.
    event EditionRoyalty(
        uint256 indexed editionId,
        address receiver,
        uint96 royaltyFraction
    );

    /// @dev Emitted when a signature is no longer required to mint tokens for a specific edition.
    event EditionSignatureReleased(uint256 indexed editionId);

    // /// @dev Emitted when the soulbound state of an edition is changed.
    // event EditionSoulbound(uint256 indexed editionId, bool soulbound);

    /// @dev Emitted when edition tokens are minted during a mint stage.
    event EditionStageMint(
        uint256 indexed editionId,
        uint256 indexed stageIndex,
        address indexed recipient,
        uint256 quantity,
        uint256 editionMintedCount
    );

    /// @dev Emitted when the metadata URI for an edition is changed.
    event EditionURI(uint256 indexed editionId, string uri);

    /// @dev Emitted when the metadata of a token is changed.
    event MetadataUpdate(uint256 _tokenId);

    /// @dev Emitted when the primary sale receiver address is changed.
    event PrimarySaleReceiver(address primarySaleReceiver_);

    /**
     * @dev Mints the same quantity of tokens from an edition to multiple recipients.
     *
     * @param editionId the ID of the edition to mint
     * @param quantity the number of tokens to mint to each recipient
     * @param recipients addresses to mint to
     */
    function airdropEdition(
        uint256 editionId,
        uint256 quantity,
        address[] memory recipients
    ) external;

    /**
     * @dev Adds new editions at the next token ID/range (depending on standard implemented)
     *
     * @param editions the editions to add
     */
    function createEditions(EditionCreateParams[] calldata editions) external;

    /**
     * @dev Delete an edition i.e. make it no longer editable or mintable.
     *
     * @param editionId the ID of the edition to delete
     */
    function deleteEdition(uint256 editionId) external;

    /**
     * @dev Returns the current total supply of tokens for an edition, taking both mints and burns into account.
     *
     * @param editionId the ID of the edition
     *
     * @return totalSupply the number of tokens in circulation
     */
    function editionTotalSupply(
        uint256 editionId
    ) external view returns (uint256 totalSupply);

    /**
     * @dev Returns the edition with ID `editionId`.
     * @dev Should revert if the edition does not exist.
     *
     * @param editionId the ID of the edition
     *
     * @return edition
     */
    function getEdition(
        uint256 editionId
    ) external view returns (Edition memory);

    /**
     * @dev Grants the `DEFAULT_ADMIN_ROLE` role to an address.
     * @dev Intended to be used only by the contract owner. Other admin management is done via AccessControl contract functions.
     *
     * @param admin the address to grant the default admin role to
     */
    function grantDefaultAdmin(address admin) external;

    /**
     * @dev Mint a quantity of tokens for an edition to a single recipient.
     * @dev Can be called by any account with a valid signature and the correct value.
     *
     * @param editionId the ID of the edition
     * @param recipient the address to transfer the minted tokens to
     * @param quantity the quantity of tokens to mint
     * @param signatureNonce a value that is recorded for signature expiry and reuse prevention, typically a recent block number
     * @param signatureMaxMints the maximum number of mints specific to the recipient and validated in the signature
     * @param signature a signature containing the other function params for authorizing the execution
     */
    function mintEdition(
        uint256 editionId,
        address recipient,
        uint256 quantity,
        uint40 signatureNonce,
        uint256 signatureMaxMints,
        bytes memory signature
    ) external payable;

    /**
     * @dev Turns off signature validation for calls to `mintEdition` for a specific edition i.e. allows signature-less minting.
     *
     * @param editionId the ID of the edition
     */
    function releaseEditionSignature(uint256 editionId) external;

    /**
     * @dev Set the default royalty receiver and fraction for the collection.
     *
     * @param receiver the address to receive royalties
     * @param royaltyFraction the fraction of the sale price to pay as royalties (out of 10000)
     */
    function setDefaultRoyalty(
        address receiver,
        uint96 royaltyFraction
    ) external;

    /**
     * @dev Changes the burnable state for a specific edition.
     *
     * @param editionId the ID of the edition
     * @param burnable the burnable value to set
     */
    function setEditionBurnable(uint256 editionId, bool burnable) external;

    /**
     * @dev Updates the maximum number of tokens each wallet can mint for an edition.
     *
     * @param editionId the ID of the edition to update
     * @param maxMintsPerWallet the new maximum number of mints
     */
    function setEditionMaxMintsPerWallet(
        uint256 editionId,
        uint40 maxMintsPerWallet
    ) external;

    /**
     * @dev Updates the maximum supply available for an edition.
     *
     * @param editionId the ID of the edition to update
     * @param maxSupply the new maximum supply of tokens for the edition
     */
    function setEditionMaxSupply(uint256 editionId, uint40 maxSupply) external;

    /**
     * @notice Set Edition Royalty
     * @dev updates the edition royalty receiver and fraction, which overrides the collection default
     *
     * @param editionId the ID of the edition to update
     * @param receiver the address that should receive royalty payments
     * @param royaltyFraction the portion of the defined denominator that the receiver should be sent from a secondary sale
     */
    function setEditionRoyalty(
        uint256 editionId,
        address receiver,
        uint96 royaltyFraction
    ) external;

    /**
     * @notice Update Edition Mint Stages
     * @dev Add and update a range of mint stages for an edition.
     *
     * @param editionId the ID of the edition
     * @param firstStageIndex the index of the first stage being det
     * @param newStages the new stage data to set
     */
    function setEditionStages(
        uint256 editionId,
        uint256 firstStageIndex,
        Stage[] calldata newStages
    ) external;

    /**
     * @notice Set Edition Metadata URI
     * @dev updates the edition metadata URI
     *
     * @param editionId the ID of the edition to update
     * @param uri the URI of the metadata for the edition
     */
    function setEditionURI(uint256 editionId, string calldata uri) external;

    /**
     * @dev Updates the address that the contract balance is withdrawn to.
     *
     * @param primarySaleReceiver_ the address that should receive funds when withdraw is called
     */
    function setPrimarySaleReceiver(address primarySaleReceiver_) external;

    /**
     * @dev returns the current total supply of tokens for the collection, taking both mints and burns into account.
     *
     * @return supply the number of tokens in circulation
     */
    function totalSupply() external view returns (uint256 supply);

    /**
     * @dev See {PausableUpgradeable-_pause}.
     */
    function pause() external;

    /**
     * @dev See {PausableUpgradeable-_unpause}.
     */
    function unpause() external;

    /**
     * @dev Sends the contract balance to the primary sale receiver address stored in the contract.
     */
    function withdraw() external;
}