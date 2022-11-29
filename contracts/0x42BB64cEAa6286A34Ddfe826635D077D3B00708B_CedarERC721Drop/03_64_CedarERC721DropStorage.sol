// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

/// ========== External imports ==========
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
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

import "./types/DropERC721DataTypes.sol";
import "../terms/types/TermsDataTypes.sol";

import "./errors/IErrors.sol";

import "./CedarERC721DropLogic.sol";
import "../terms/lib/TermsLogic.sol";

import "../api/issuance/IDropClaimCondition.sol";
import "../api/metadata/IContractMetadata.sol";
import "../api/royalties/IRoyalty.sol";

abstract contract CedarERC721DropStorage is
    Initializable,
    ReentrancyGuardUpgradeable,
    ERC2771ContextUpgradeable,
    MulticallUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC721EnumerableUpgradeable,
    DefaultOperatorFiltererUpgradeable
{
    /// ================================
    /// =========== Libraries ==========
    /// ================================
    using StringsUpgradeable for uint256;
    using CedarERC721DropLogic for DropERC721DataTypes.ClaimData;
    using TermsLogic for TermsDataTypes.Terms;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /// =============================
    /// =========== Events ==========
    /// =============================
    /// @dev Emitted when the global max supply of tokens is updated.
    event MaxTotalSupplyUpdated(uint256 maxTotalSupply);
    /// @dev Emitted when the wallet claim count for an address is updated.
    event WalletClaimCountUpdated(address indexed wallet, uint256 count);
    /// @dev Emitted when the global max wallet claim count is updated.
    event MaxWalletClaimCountUpdated(uint256 count);
    /// @dev Emitted when a new sale recipient is set.
    event PrimarySaleRecipientUpdated(address indexed recipient);
    /// @dev Emitted when the terms are accepted.
    event TermsAccepted(string termsURI, uint8 termsVersion, address indexed acceptor);
    /// @dev Emitted when the terms are activated/deactivated.
    event TermsActivationStatusUpdated(bool isActivated);
    /// @dev Emitted when the terms URI is updated.
    event TermsUpdated(string termsURI, uint8 termsVersion);
    /// @dev Emitted when tokens are claimed.
    event TokensClaimed(
        uint256 indexed claimConditionIndex,
        address indexed claimer,
        address indexed receiver,
        uint256 startTokenId,
        uint256 quantityClaimed
    );
    /// @dev Emitted when new claim conditions are set.
    event ClaimConditionsUpdated(IDropClaimConditionV0.ClaimCondition[] claimConditions);
    /// @dev Emitted when tokens are lazy minted.
    event TokensLazyMinted(uint256 startTokenId, uint256 endTokenId, string baseURI);
    /// @dev Emitted when new token is issued by ISSUER.
    event TokensIssued(
        uint256 indexed startTokenId,
        address indexed issuer,
        address indexed receiver,
        uint256 quantity
    );
    /// @dev Emitted when tokens are issued.
    event TokenIssued(uint256 indexed tokenId, address indexed issuer, address indexed receiver, string tokenURI);
    /// @dev Emitted when token URI is updated.
    event TokenURIUpdated(uint256 indexed tokenId, address indexed updater, string tokenURI);
    /// @dev Emitted when contractURI is updated
    event ContractURIUpdated(address indexed updater, string uri);
    /// @dev Emitted when base URI is updated.
    event BaseURIUpdated(uint256 baseURIIndex, string baseURI);
    /// @dev Emitted when royalty info is updated.
    event DefaultRoyalty(address newRoyaltyRecipient, uint256 newRoyaltyBps);
    /// @dev Emitted when royalty recipient for tokenId is set
    event RoyaltyForToken(uint256 indexed tokenId, address royaltyRecipient, uint256 royaltyBps);
    /// @dev Event emitted when claim functionality is paused/un-paused.
    event ClaimPauseStatusUpdated(bool pauseStatus);

    /// ===============================================
    /// =========== State variables - public ==========
    /// ===============================================
    /// @dev Contract level metadata.
    string public _contractUri;
    /// @dev Only transfers to or from TRANSFER_ROLE holders are valid, when transfers are restricted.
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    /// @dev Only MINTER_ROLE holders can lazy mint NFTs.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /// @dev Only ISSUER_ROLE holders can issue NFTs.
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    /// @dev If true, users cannot claim.
    bool public claimIsPaused = false;
    /// ================================================
    /// =========== State variables - private ==========
    /// ================================================
    /// @dev Owner of the contract (purpose: OpenSea compatibility)
    address public _owner;
    /// @dev The (default) address that receives all royalty value.
    address public royaltyRecipient;
    /// @dev Token ID => royalty recipient and bps for token
    mapping(uint256 => IRoyaltyV0.RoyaltyInfo) public royaltyInfoForToken;
    /// @dev
    address public delegateLogicContract;

    DropERC721DataTypes.ClaimData claimData;
    TermsDataTypes.Terms termsData;

    /// @dev See ERC 165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721EnumerableUpgradeable, AccessControlEnumerableUpgradeable)
        returns (bool)
    {
        return
            ERC721EnumerableUpgradeable.supportsInterface(interfaceId) ||
            AccessControlEnumerableUpgradeable.supportsInterface(interfaceId);
    }

    /// @dev See {ERC721-_beforeTokenTransfer}.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);

        // if transfer is restricted on the contract, we still want to allow burning and minting
        if (!hasRole(TRANSFER_ROLE, address(0)) && from != address(0) && to != address(0)) {
            if (!(hasRole(TRANSFER_ROLE, from) || hasRole(TRANSFER_ROLE, to))) revert InvalidPermission();
        }

        if (to != address(this)) {
            if (termsData.termsActivated) {
                if (!termsData.termsAccepted[to] || termsData.termsVersion != termsData.acceptedVersion[to])
                    revert TermsNotAccepted(to, termsData.termsURI, termsData.termsVersion);
            }
        }
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