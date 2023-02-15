// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "../libraries/Errors.sol";
import "../interfaces/ISoulboundIdentity.sol";
import "../dex/PaymentGateway.sol";
import "./MasaSBT.sol";

/// @title MasaSBTSelfSovereign
/// @author Masa Finance
/// @notice Soulbound token. Non-fungible token that is not transferable.
/// Adds a link to a SoulboundIdentity SC to let minting using the identityId
/// Adds a payment gateway to let minting paying a fee
/// Adds a self-sovereign protocol to let minting using an authority signature
/// @dev Implementation of https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4105763 Soulbound token.
abstract contract MasaSBTSelfSovereign is PaymentGateway, MasaSBT, EIP712 {
    /* ========== STATE VARIABLES =========================================== */

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    ISoulboundIdentity public soulboundIdentity;

    uint256 public mintPrice; // price in stable coin
    uint256 public mintPriceMASA; // price in MASA

    mapping(address => bool) public authorities;

    /* ========== INITIALIZE ================================================ */

    /// @notice Creates a new soulbound token
    /// @dev Creates a new soulbound token
    /// @param admin Administrator of the smart contract
    /// @param name Name of the token
    /// @param symbol Symbol of the token
    /// @param baseTokenURI Base URI of the token
    /// @param _soulboundIdentity Address of the SoulboundIdentity contract
    /// @param paymentParams Payment gateway params
    constructor(
        address admin,
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        ISoulboundIdentity _soulboundIdentity,
        PaymentParams memory paymentParams
    )
        PaymentGateway(admin, paymentParams)
        MasaSBT(admin, name, symbol, baseTokenURI)
    {
        soulboundIdentity = _soulboundIdentity;
    }

    /* ========== RESTRICTED FUNCTIONS ====================================== */

    /// @notice Sets the SoulboundIdentity contract address linked to this SBT
    /// @dev The caller must be the admin to call this function
    /// @param _soulboundIdentity Address of the SoulboundIdentity contract
    function setSoulboundIdentity(ISoulboundIdentity _soulboundIdentity)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (soulboundIdentity == _soulboundIdentity) revert SameValue();
        soulboundIdentity = _soulboundIdentity;
    }

    /// @notice Sets the price of minting in stable coin
    /// @dev The caller must have the admin role to call this function
    /// @param _mintPrice New price of minting in stable coin
    function setMintPrice(uint256 _mintPrice)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (mintPrice == _mintPrice) revert SameValue();
        mintPrice = _mintPrice;
    }

    /// @notice Sets the price of minting in MASA
    /// @dev The caller must have the admin role to call this function
    /// @param _mintPriceMASA New price of minting in MASA
    function setMintPriceMASA(uint256 _mintPriceMASA)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (mintPriceMASA == _mintPriceMASA) revert SameValue();
        mintPriceMASA = _mintPriceMASA;
    }

    /// @notice Adds a new authority to the list of authorities
    /// @dev The caller must have the admin role to call this function
    /// @param _authority New authority to add
    function addAuthority(address _authority)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (_authority == address(0)) revert ZeroAddress();
        if (authorities[_authority]) revert AlreadyAdded();

        authorities[_authority] = true;
    }

    /// @notice Removes an authority from the list of authorities
    /// @dev The caller must have the admin role to call this function
    /// @param _authority Authority to remove
    function removeAuthority(address _authority)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (_authority == address(0)) revert ZeroAddress();
        if (!authorities[_authority]) revert AuthorityNotExists(_authority);

        authorities[_authority] = false;
    }

    /* ========== MUTATIVE FUNCTIONS ======================================== */

    /* ========== VIEWS ===================================================== */

    /// @notice Returns the identityId owned by the given token
    /// @param tokenId Id of the token
    /// @return Id of the identity
    function getIdentityId(uint256 tokenId) external view returns (uint256) {
        if (soulboundIdentity == ISoulboundIdentity(address(0)))
            revert NotLinkedToAnIdentitySBT();

        address owner = super.ownerOf(tokenId);
        return soulboundIdentity.tokenOfOwner(owner);
    }

    /// @notice Returns the price for minting
    /// @dev Returns current pricing for minting
    /// @param paymentMethod Address of token that user want to pay
    /// @return Current price for minting in the given payment method
    function getMintPrice(address paymentMethod) public view returns (uint256) {
        if (mintPrice == 0 && mintPriceMASA == 0) {
            return 0;
        } else if (
            paymentMethod == masaToken &&
            enabledPaymentMethod[paymentMethod] &&
            mintPriceMASA > 0
        ) {
            // price in MASA without conversion rate
            return mintPriceMASA;
        } else if (
            paymentMethod == stableCoin && enabledPaymentMethod[paymentMethod]
        ) {
            // stable coin
            return mintPrice;
        } else if (enabledPaymentMethod[paymentMethod]) {
            // ETH and ERC 20 token
            return _convertFromStableCoin(paymentMethod, mintPrice);
        } else {
            revert InvalidPaymentMethod(paymentMethod);
        }
    }

    /// @notice Query if a contract implements an interface
    /// @dev Interface identification is specified in ERC-165.
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @return `true` if the contract implements `interfaceId` and
    ///  `interfaceId` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, MasaSBT)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /* ========== PRIVATE FUNCTIONS ========================================= */

    function _verify(
        bytes32 digest,
        bytes memory signature,
        address signer
    ) internal view {
        address _signer = ECDSA.recover(digest, signature);
        if (_signer != signer) revert InvalidSignature();
        if (!authorities[_signer]) revert NotAuthorized(_signer);
    }

    function _mintWithCounter(address to) internal virtual returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(to, tokenId);

        return tokenId;
    }

    /* ========== MODIFIERS ================================================= */

    /* ========== EVENTS ==================================================== */
}