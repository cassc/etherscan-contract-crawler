// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IAccessControl, AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/DefaultOperatorFilterer.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {ERC721A, ERC721AURIStorage} from "./ERC721AURIStorage.sol";
import {DPVoucher, DigitalPaintVoucher} from "./DigitalPaintVoucher.sol";

contract DigitalPaint is
    ERC721AURIStorage,
    ERC2981,
    DigitalPaintVoucher,
    AccessControl,
    DefaultOperatorFilterer,
    ReentrancyGuard
{
    using Strings for uint256;

    /// @notice Raised when attempting to update an Artist Choice token
    error CannotUpdateArtistChoice();
    /// @notice Raised when attempting to burn an Artist Choice token
    error CannotBurnArtistChoice();
    /// @notice Raised when attempting to mint or update using an invalid voucher
    error InvalidVoucher();
    /// @notice Raised when attempting to mint or update using an expired voucher
    error VoucherExpired();
    /// @notice Raised when attempting to update metadata after freeze has taken place
    error MetadataFrozen();
    /// @notice Raised when a non-EOA account calls a gated function
    error OnlyEOA(address msgSender);
    /// @notice Raised when trying to access token that does not exist
    error TokenDoesNotExist();
    /// @notice Raised when an unauthorized account attempts to perform an action
    error Unauthorized();
    /// @notice Raised when a call is made to update a token while updates are disabled
    error UpdatesDisabled();

    /// @notice Emitted when a token is updated with new painting data
    event PaintingUpdated(
        uint256 indexed tokenId,
        address indexed updatedBy,
        string oldURI,
        string newURI
    );

    /// @notice Access Control role for administrative functions
    bytes32 public constant ADMIN = keccak256("ADMIN");
    /// @notice Access Control role authorizing account to sign DigitalPaintVouchers
    bytes32 public constant SIGNER = keccak256("SIGNER");
    /// @notice Access Control role authorizing account to mint tokens
    bytes32 public constant MINTER = keccak256("MINTER");
    /// @notice Once flipped to TRUE, metadata will be irrevocably frozen
    bool public metadataFrozen;
    /// @notice Whether updates for tokens 101-1000 are enabled
    bool public updatesEnabled = false;

    constructor(
        address saleContract,
        address signer,
        address cutMod,
        address chainSaw,
        address payable royaltySplitter,
        address[] memory admins
    )
        ERC721A("Digital Paint", "DIGITALPAINT")
        DigitalPaintVoucher("DigitalPaint", "1")
    {
        _setDefaultRoyalty(royaltySplitter, 750);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SIGNER, signer);
        _setupRole(MINTER, saleContract);
        // Set up admin roles
        for (uint256 i = 0; i < admins.length; i++) {
            _setupRole(ADMIN, admins[i]);
        }
        // Mint Artist Choice to sale contract
        _mint(saleContract, 100);
        // Mint 50 Paint Passes to the contract deployer
        _mint(msg.sender, 30);
        _mint(cutMod, 10);
        _mint(chainSaw, 10);
    }

    ////////////////////////////////////////////////////////////////////////////
    // MODIFIERS
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Modifier to ensure that only accounts with the ADMIN role can call a function
    modifier onlyAdmin() {
        if (
            !hasRole(ADMIN, msg.sender) &&
            !hasRole(DEFAULT_ADMIN_ROLE, msg.sender)
        ) revert Unauthorized();
        _;
    }

    /// @notice Modifier to ensure that only accounts with the MINTER role can call a function
    modifier onlyMinter() {
        if (!hasRole(MINTER, msg.sender)) revert Unauthorized();
        _;
    }

    ////////////////////////////////////////////////////////////////////////////
    // WRITES
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Permissioned mint function to be called by sale contract
    /// @param to The address to mint the Digital Paint NFT to
    /// @param amount The amount of Digital Paint NFTs to mint
    function mint(address to, uint256 amount) external onlyMinter {
        _mint(to, amount);
    }

    /// @notice Update the tokenURI of an existing Digital Paint NFT
    /// @param tokenId The ID of the Digital Paint NFT to update
    /// @param _tokenURI The new tokenURI of the Digital Paint NFT
    /// @param expiration The expiration of the Digital Paint Voucher
    /// @param signature The signature representing a valid Digital Paint Voucher
    function update(
        uint256 tokenId,
        string calldata _tokenURI,
        uint256 expiration,
        bytes calldata signature
    ) external {
        if (metadataFrozen) revert MetadataFrozen();
        if (!updatesEnabled) revert UpdatesDisabled();
        if (_isArtistChoice(tokenId)) revert CannotUpdateArtistChoice();
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        if (ownerOf(tokenId) != msg.sender) revert Unauthorized();
        _checkVoucher(tokenId, _tokenURI, expiration, signature);
        string memory prevURI = tokenURI(tokenId);
        _setTokenURI(tokenId, _tokenURI);
        emit PaintingUpdated(tokenId, msg.sender, prevURI, _tokenURI);
    }

    ////////////////////////////////////////////////////////////////////////////
    // ADMIN
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Allows admin to burn a Digital Paint NFT
    /// @param tokenId The ID of the Digital Paint NFT to burn
    function adminBurn(uint256 tokenId) external onlyAdmin {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        if (_isArtistChoice(tokenId)) revert CannotBurnArtistChoice();
        _burn(tokenId);
    }

    /// @notice Allows admin to update tokenURI of a Digital Paint NFT
    /// @param tokenId The ID of the Digital Paint NFT to update
    /// @param _tokenURI The new tokenURI of the Digital Paint NFT
    function adminUpdate(uint256 tokenId, string memory _tokenURI)
        external
        onlyAdmin
    {
        if (metadataFrozen) revert MetadataFrozen();
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        if (_isArtistChoice(tokenId)) revert CannotUpdateArtistChoice();
        string memory prevURI = tokenURI(tokenId);
        _setTokenURI(tokenId, _tokenURI);
        emit PaintingUpdated(tokenId, msg.sender, prevURI, _tokenURI);
    }

    /// @notice Irrevocably freeze metadata. Once frozen, metadata cannot be updated.
    function freezeMetadata() external onlyAdmin {
        if (metadataFrozen) revert MetadataFrozen();
        metadataFrozen = true;
    }

    /// @notice Set the base tokenURI for all Digital Paint NFTs
    function setBaseTokenURI(string memory baseTokenURI) external onlyAdmin {
        if (metadataFrozen) revert MetadataFrozen();
        _setBaseTokenURI(baseTokenURI);
    }

    /// @notice Set whether to ignore individually set tokenURIs
    function setForceBaseTokenURI(bool forceBaseTokenURI) external onlyAdmin {
        if (metadataFrozen) revert MetadataFrozen();
        _setForceBaseTokenURI(forceBaseTokenURI);
    }

    /// @notice Toggle whether updates for tokens 101-5000 are enabled
    function toggleUpdates() external onlyAdmin {
        updatesEnabled = !updatesEnabled;
    }

    /// @notice Set the default royalty for all Digital Paint NFTs
    /// @param receiver The address to receive royalties
    /// @param feeNumerator The numerator of the royalty fee
    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyAdmin
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    ////////////////////////////////////////////////////////////////////////////
    // INTERNAL GUYS
    ////////////////////////////////////////////////////////////////////////////

    /// @dev Revert if the account is a smart contract. Does not protect against calls from the constructor.
    /// @param account The account to check
    function _onlyEOA(address account) internal view {
        if (msg.sender != tx.origin || account.code.length > 0) {
            revert OnlyEOA(account);
        }
    }

    /// @notice Check if a Digital Paint Voucher is valid. Revert if Invalid or Expired.
    /// @param tokenId The ID of the Digital Paint NFT to check
    /// @param uri The verified URI of the Digital Paint NFT
    /// @param expiration The expiration of the Digital Paint Voucher
    /// @param signature The signature representing a valid Digital Paint Voucher
    function _checkVoucher(
        uint256 tokenId,
        string calldata uri,
        uint256 expiration,
        bytes calldata signature
    ) internal view {
        if (block.timestamp > expiration) revert VoucherExpired();
        address signer = _recoverSigner(
            DPVoucher(tokenId, msg.sender, uri, expiration),
            signature
        );
        if (!hasRole(SIGNER, signer)) revert InvalidVoucher();
    }

    /// @notice Helper to check whether @param tokenId is an Artist Choice NFT
    /// @param tokenId The ID of the Digital Paint NFT to check
    function _isArtistChoice(uint256 tokenId) internal pure returns (bool) {
        return tokenId >= 1 && tokenId <= 100;
    }

    ////////////////////////////////////////////////////////////////////////////
    // OPERATOR FILTER REGISTRY
    ////////////////////////////////////////////////////////////////////////////

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    ////////////////////////////////////////////////////////////////////////////
    // OVERRIDES
    ////////////////////////////////////////////////////////////////////////////

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            interfaceId == 0x2a55205a || // ERC165 Interface ID for ERC2981
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }
}