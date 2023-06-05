// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title DroppableEditionsStorage
 * @author MirrorXYZ
 */
contract DroppableEditionsStorage {
    // ============ Structs ============

    /// @notice Contains general data about the NFT.
    struct NFTMetadata {
        string name;
        string symbol;
        string baseURI;
        bytes32 contentHash;
    }

    /// @notice Contains information pertaining to the edition spec.
    struct EditionData {
        // The maximum number of tokens that can be sold.
        uint256 quantity;
        uint256 allocation;
        // The price at which each token will be sold, in ETH.
        uint256 price;
    }

    /// @notice Contains information about funds disbursement.
    struct AdminData {
        // Operator of this contract.
        address operator;
        bytes32 merkleRoot;
        // Address that receive gov tokens via treasury.
        address tributary;
        // The account that will receive sales revenue.
        address payable fundingRecipient;
        // The fee taken when withdrawing funds
        uint256 feePercentage;
    }

    // ============ Storage for Setup ============

    /// @notice NFTMetadata`
    string public baseURI;
    bytes32 contentHash;

    /// @notice EditionData
    uint256 public allocation;
    uint256 public quantity;
    uint256 public price;

    /// @notice EditionConfig
    address public operator;
    address public tributary;
    address payable public fundingRecipient;
    uint256 feePercentage;

    /// @notice Treasury Config, provided at setup, for finding the treasury address.
    address treasuryConfig;

    // ============ Mutable Runtime Storage ============

    /// @notice `nextTokenId` increments with each token purchased, globally across all editions.
    uint256 internal nextTokenId;
    /// @notice The number of tokens that have moved outside of the pre-mint allocation.
    uint256 internal allocationsTransferred = 0;

    /**
     * @notice A special mapping of burned tokens, to take care of burning within
     * the tokenId range of the allocation.
     */
    mapping(uint256 => bool) internal _burned;

    // ============ Mutable Internal NFT Storage ============

    mapping(uint256 => address) internal _owners;
    mapping(address => uint256) internal _balances;
    mapping(uint256 => address) internal _tokenApprovals;
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    /// @notice Only allow one purchase per account.
    mapping(address => bool) internal purchased;

    // OpenSea's Proxy Registry
    address public proxyRegistry;

    bytes32 public merkleRoot;

    uint256 currentTokenId;
    uint256 currentIndexId;
    uint256 claimedTokens;
    uint256 nonAllocatedPurchases = 0;

    mapping(uint256 => bool) public burned;

    mapping(uint256 => address) public indexToClaimer;
    mapping(address => uint256) public claimerToAllocation;

    mapping(bytes32 => bool) public claimed;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /// @notice Allows to renounce upgrades
    bool public upgradesAllowed = true;
}