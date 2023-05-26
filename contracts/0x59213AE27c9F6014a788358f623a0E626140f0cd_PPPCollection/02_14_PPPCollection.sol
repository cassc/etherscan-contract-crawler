// SPDX-License-Identifier: MIT
// Copyright (c) 2022-2023 Fellowship

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

interface IOperatorFilterRegistry {
    function isOperatorAllowed(address contract_, address operator) external view returns (bool);

    function registerAndSubscribe(address contract_, address subscription) external;
}

/// @title Token Base
/// @notice Shared logic for token contracts
contract PPPCollection is ERC721, Ownable {
    /// @notice The OpenSea OperatorFilterRegistry deployment
    IOperatorFilterRegistry private constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    uint256 private immutable MAX_SUPPLY;

    address public royaltyReceiver;
    address public minter;
    address public metadataContract;

    uint256 public royaltyFraction;
    uint256 public royaltyDenominator = 100;

    /// @notice Count of valid NFTs tracked by this contract
    uint256 public totalSupply;

    /// @notice Return the baseURI used for computing `tokenURI` values
    string public baseURI;

    error OnlyMinter();
    error OperatorNotAllowed(address operator);

    /// @dev This event emits when the metadata of a token is changed. Anyone aware of ERC-4906 can update cached
    ///  attributes related to a given `tokenId`.
    event MetadataUpdate(uint256 tokenId);

    /// @dev This event emits when the metadata of a range of tokens is changed. Anyone aware of ERC-4906 can update
    ///  cached attributes for tokens in the designated range.
    event BatchMetadataUpdate(uint256 fromTokenId, uint256 toTokenId);

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI_,
        uint256 maxSupply,
        address royaltyReceiver_,
        uint256 royaltyPercent
    ) ERC721(name, symbol) {
        // CHECKS inputs
        require(maxSupply > 0, "Max supply must not be zero");
        require(royaltyReceiver_ != address(0), "Royalty receiver must not be the zero address");
        require(royaltyPercent <= 100, "Royalty fraction must not be greater than 100%");

        // EFFECTS
        MAX_SUPPLY = maxSupply;
        baseURI = baseURI_;
        royaltyReceiver = royaltyReceiver_;
        royaltyFraction = royaltyPercent;

        // INTERACTIONS
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            // Subscribe to the "OpenSea Curated Subscription Address"
            OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);
        }
    }

    modifier onlyMinter() {
        if (msg.sender != minter) revert OnlyMinter();
        _;
    }

    // HOLDER FUNCTIONS

    /// @notice Enable or disable approval for an `operator` to manage all assets belonging to the sender
    /// @dev Emits the ApprovalForAll event. The contract MUST allow multiple operators per owner.
    /// @param operator Address to add to the set of authorized operators
    /// @param approved True to grant approval, false to revoke approval
    function setApprovalForAll(address operator, bool approved) public virtual override {
        // CHECKS inputs
        if (approved && !operatorAllowed(operator)) revert OperatorNotAllowed(operator);
        // CHECKS + EFFECTS
        super.setApprovalForAll(operator, approved);
    }

    // MINTER FUNCTIONS

    /// @notice Mint an unclaimed token to the given address
    /// @dev Can only be called by the `minter` address
    /// @param to The new token owner that will receive the minted token
    /// @param tokenId The token being claimed. Reverts if invalid or already claimed.
    function mint(address to, uint256 tokenId) external onlyMinter {
        // CHECKS inputs
        require(tokenId < MAX_SUPPLY, "Invalid token ID");
        // CHECKS + EFFECTS (not _safeMint, so no interactions)
        _mint(to, tokenId);
        // More EFFECTS
        unchecked {
            totalSupply++;
        }
    }

    // OWNER FUNCTIONS

    /// @notice Set the `minter` address
    /// @dev Can only be called by the contract `owner`
    function setMinter(address minter_) external onlyOwner {
        minter = minter_;
    }

    /// @notice Set the `royaltyReceiver` address
    /// @dev Can only be called by the contract `owner`
    function setRoyaltyReceiver(address royaltyReceiver_) external onlyOwner {
        // CHECKS inputs
        require(royaltyReceiver_ != address(0), "Royalty receiver must not be the zero address");
        // EFFECTS
        royaltyReceiver = royaltyReceiver_;
    }

    /// @notice Update the royalty fraction
    /// @dev Can only be called by the contract `owner`
    function setRoyaltyFraction(uint256 royaltyFraction_, uint256 royaltyDenominator_) external onlyOwner {
        // CHECKS inputs
        require(royaltyDenominator_ != 0, "Royalty denominator must not be zero");
        require(royaltyFraction_ <= royaltyDenominator_, "Royalty fraction must not be greater than 100%");
        // EFFECTS
        royaltyFraction = royaltyFraction_;
        royaltyDenominator = royaltyDenominator_;
    }

    /// @notice Update the baseURI for all metadata
    /// @dev Can only be called by the contract `owner`. Emits an ERC-4906 event.
    /// @param baseURI_ The new URI base. When specified, token URIs are created by concatenating the baseURI,
    ///  token ID, and ".json".
    function updateBaseURI(string calldata baseURI_) external onlyOwner {
        // CHECKS inputs
        require(bytes(baseURI_).length > 0, "New base URI must be provided");

        // EFFECTS
        baseURI = baseURI_;
        metadataContract = address(0);

        emit BatchMetadataUpdate(0, MAX_SUPPLY - 1);
    }

    /// @notice Delegate all `tokenURI` calls to another contract
    /// @dev Can only be called by the contract `owner`. Emits an ERC-4906 event.
    /// @param delegate The contract that will handle `tokenURI` responses
    function delegateTokenURIs(address delegate) external onlyOwner {
        // CHECKS inputs
        require(delegate != address(0), "New metadata delegate must not be the zero address");
        require(delegate.code.length > 0, "New metadata delegate must be a contract");

        // EFFECTS
        baseURI = "";
        metadataContract = delegate;

        emit BatchMetadataUpdate(0, MAX_SUPPLY - 1);
    }

    // VIEW FUNCTIONS

    /// @notice The URI for the given token
    /// @dev Throws if `tokenId` is not valid or has not been minted
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        if (bytes(baseURI).length > 0) {
            return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
        }

        if (address(metadataContract) != address(0)) {
            return IERC721Metadata(metadataContract).tokenURI(tokenId);
        }

        revert("tokenURI not configured");
    }

    /// @notice Return whether the given tokenId has been minted yet
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    /// @notice Calculate how much royalty is owed and to whom
    /// @param salePrice - the sale price of the NFT asset
    /// @return receiver - address of where the royalty payment should be sent
    /// @return royaltyAmount - the royalty payment amount for salePrice
    function royaltyInfo(uint256, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        receiver = royaltyReceiver;
        // Use OpenZeppelin math utils for full precision multiply and divide without overflow
        royaltyAmount = Math.mulDiv(salePrice, royaltyFraction, royaltyDenominator, Math.Rounding.Up);
    }

    /// @notice Query if a contract implements an interface
    /// @dev Interface identification is specified in ERC-165. This function uses less than 30,000 gas.
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @return `true` if the contract implements `interfaceID` and `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
        return
            interfaceId == 0x80ac58cd || // ERC-721 Non-Fungible Token Standard
            interfaceId == 0x5b5e139f || // ERC-721 Non-Fungible Token Standard - metadata extension
            interfaceId == 0x2a55205a || // ERC-2981 NFT Royalty Standard
            interfaceId == 0x49064906 || // ERC-4906 Metadata Update Extension
            interfaceId == 0x7f5828d0 || // ERC-173 Contract Ownership Standard
            interfaceId == 0x01ffc9a7; // ERC-165 Standard Interface Detection
    }

    // PRIVATE FUNCTIONS

    /// @dev OpenZeppelin hook that is called before any token transfer, including minting and burning
    function _beforeTokenTransfer(address from, address to, uint256 id, uint256 quantity) internal virtual override {
        if (from != address(0) && from != msg.sender && !operatorAllowed(msg.sender)) {
            revert OperatorNotAllowed(msg.sender);
        }

        super._beforeTokenTransfer(from, to, id, quantity);
    }

    function operatorAllowed(address operator) internal view returns (bool) {
        return
            address(OPERATOR_FILTER_REGISTRY).code.length == 0 ||
            OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator);
    }
}