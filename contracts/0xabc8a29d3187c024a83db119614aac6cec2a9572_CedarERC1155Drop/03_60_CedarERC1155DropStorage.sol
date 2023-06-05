// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

//  ==========  External imports    ==========
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

/// ========== Features ==========
import "./interfaces/IOwnable.sol";
import "./interfaces/IPlatformFee.sol";

import "./openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";

import "./types/DropERC1155DataTypes.sol";
import "../terms/types/TermsDataTypes.sol";

import "./errors/IErrors.sol";

import "./CedarERC1155DropLogic.sol";
import "../terms/lib/TermsLogic.sol";
import "../api/issuance/IDropClaimCondition.sol";

abstract contract CedarERC1155DropStorage is
    Initializable,
    ReentrancyGuardUpgradeable,
    ERC2771ContextUpgradeable,
    MulticallUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC1155Upgradeable,
    DefaultOperatorFiltererUpgradeable
{
    /// ================================
    /// =========== Libraries ==========
    /// ================================
    using StringsUpgradeable for uint256;
    using TermsLogic for TermsDataTypes.Terms;
    using CedarERC1155DropLogic for DropERC1155DataTypes.ClaimData;

    /// =============================
    /// =========== Events ==========
    /// =============================
    /// @dev Emitted when the global max supply of a token is updated.
    event MaxTotalSupplyUpdated(uint256 tokenId, uint256 maxTotalSupply);
    /// @dev Emitted when the wallet claim count for a given tokenId and address is updated.
    event WalletClaimCountUpdated(uint256 tokenId, address indexed wallet, uint256 count);
    /// @dev Emitted when the max wallet claim count for a given tokenId is updated.
    event MaxWalletClaimCountUpdated(uint256 tokenId, uint256 count);
    /// @dev Emitted when the sale recipient for a particular tokenId is updated.
    event SaleRecipientForTokenUpdated(uint256 indexed tokenId, address saleRecipient);
    /// @dev Emitted when the terms are accepted.
    event TermsAccepted(string termsURI, uint8 termsVersion, address indexed acceptor);
    /// @dev Emitted when the terms are activated/deactivated.
    event TermsActivationStatusUpdated(bool isActivated);
    /// @dev Emitted when the terms URI is updated.
    event TermsUpdated(string termsURI, uint8 termsVersion);
    /// @dev Emitted when base URI is updated.
    event BaseURIUpdated(uint256 baseURIIndex, string baseURI);
    /// @dev Emitted when contractURI is updated
    event ContractURIUpdated(address indexed updater, string uri);
    /// @dev Emitted when tokens are claimed.
    event TokensClaimed(
        uint256 indexed claimConditionIndex,
        uint256 indexed tokenId,
        address indexed claimer,
        address receiver,
        uint256 quantityClaimed
    );
    /// @dev Emitted when tokens are issued.
    event TokensIssued(uint256 indexed tokenId, address indexed claimer, address receiver, uint256 quantityClaimed);
    /// @dev Emitted when new claim conditions are set for a token.
    event ClaimConditionsUpdated(uint256 indexed tokenId, IDropClaimConditionV0.ClaimCondition[] claimConditions); // missing
    /// @dev Emitted when tokens are lazy minted.
    event TokensLazyMinted(uint256 startTokenId, uint256 endTokenId, string baseURI);
    /// @dev Emitted when a new sale recipient is set.
    event PrimarySaleRecipientUpdated(address indexed recipient);
    /// @dev Emitted when royalty info is updated.
    event DefaultRoyalty(address newRoyaltyRecipient, uint256 newRoyaltyBps);
    /// @dev Emitted when royalty recipient for tokenId is set
    event RoyaltyForToken(uint256 indexed tokenId, address royaltyRecipient, uint256 royaltyBps);
    /// @dev Event emitted when claim functionality is paused/un-paused.
    event ClaimPauseStatusUpdated(bool pauseStatus);

    /// ===============================================
    /// =========== State variables - public ==========
    /// ===============================================
    /// @dev If true, users cannot claim.
    bool public claimIsPaused = false;
    // FIXME: TRANSFER_ROLE is duplicated on CedarERC1155DropLogic (since we wish to access it from this contract externally)
    /// @dev Only transfers to or from TRANSFER_ROLE holders are valid, when transfers are restricted.
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    /// @dev Only MINTER_ROLE holders can lazy mint NFTs.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /// @dev Only ISSUER_ROLE holders can issue NFTs.
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    /// @dev The address that receives all primary sales value.
    address public _primarySaleRecipient;
    /// @dev Token name
    string public name;
    /// @dev Token symbol
    string public symbol;
    /// @dev Owner of the contract (purpose: OpenSea compatibility)
    address public _owner;
    uint256[] public baseURIIndices;
    /// @dev Contract level metadata.
    string public _contractUri;
    /// @dev Mapping from 'Largest tokenId of a batch of tokens with the same baseURI'
    ///         to base URI for the respective batch of tokens.
    mapping(uint256 => string) public baseURI;

    address public delegateLogicContract;

    DropERC1155DataTypes.ClaimData claimData;
    TermsDataTypes.Terms termsData;

    /// @dev See ERC 165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Upgradeable, AccessControlEnumerableUpgradeable)
        returns (bool)
    {
        return
            ERC1155Upgradeable.supportsInterface(interfaceId) ||
            AccessControlEnumerableUpgradeable.supportsInterface(interfaceId);
    }

    /// @dev See {ERC1155-_beforeTokenTransfer}.
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        CedarERC1155DropLogic.beforeTokenTransfer(claimData, termsData, this, from, to, ids, amounts);
    }

    /// ======================================
    /// =========== Miscellaneous ============
    /// ======================================
    /// @dev Provides a function to batch together multiple calls in a single external call.
    function multicall(bytes[] calldata data) external virtual override returns (bytes[] memory results) {
        return MulticallUpgradeable(this).multicall(data);
    }

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }
}