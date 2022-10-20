// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// pragma experimental ABIEncoderV2;
import {LibDiamond} from "../libraries/LibDiamond.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControl} from "../abstracts/AccessControl.sol";

struct TokenApprovalRef {
    address value;
}

struct RoyaltyInfo {
    address receiver;
    uint96 royaltyFraction;
}

struct RoleData {
    mapping(address => bool) members;
    bytes32 adminRole;
}

struct Edition {
    string name;
    uint256 maxSupply;
    uint256 totalSupply;
    uint256 price;
}

// TODO: Minimum savings from packing the struct. But would require redeployin all facets. Probably not worth it.abi
// TODO: Revert back to old structure and add new items to the end?
struct AppStorage {
    /**
     * @dev ERC721A Section
     */
    // The tokenId of the next token to be minted.
    uint256 currentIndex;
    // The number of tokens burned.
    uint256 burnCounter;
    // Token name
    string name;
    // Token symbol
    string symbol;
    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See {_packedOwnershipOf} implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    // - [232..255] `extraData`
    mapping(uint256 => uint256) packedOwnerships;
    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) packedAddressData;
    // Mapping from token ID to approved address.
    mapping(uint256 => TokenApprovalRef) tokenApprovals;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) operatorApprovals;
    /**
     * @dev PaymentSplitter Section
     */
    uint256 totalShares;
    uint256 totalReleased;
    mapping(address => uint256) shares;
    mapping(address => uint256) released;
    address[] payees;
    mapping(IERC20 => uint256) erc20TotalReleased;
    mapping(IERC20 => mapping(address => uint256)) erc20Released;
    bool isPriceUSD;
    bool automaticUSDConversion;
    /**
     * @dev Royalty/ERC2981/ContractURI Section
     */
    RoyaltyInfo defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) tokenRoyaltyInfo;
    string contractURI;
    address secondaryPayee;
    uint256 secondaryPoints;
    /**
     * @dev Custom ERC721A Variables
     */
    uint256 price;
    uint256 maxSupply;
    string baseTokenUri;
    bool airdrop;
    bool paused;
    uint256 maxMintPerTx;
    uint256 maxMintPerAddress;
    // Allow list
    bytes32 allowListRoot;
    bool allowListEnabled;
    /**
     * @dev Access Control
     */
    mapping(bytes32 => RoleData) roles;
    bytes32 DEFAULT_ADMIN_ROLE;
    bytes32 OWNER_ROLE;
    /**
     * @dev Editions
     */
    bool editionsEnabled;
    Edition[] editionsByIndex; // Editions
    mapping(uint256 => uint256) tokenEdition; // idToken => editionIndex
    /**
     * @dev Soulbound!!
     */
    bool isSoulbound;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }

    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }
}