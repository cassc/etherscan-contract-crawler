// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { ERC721A } from "erc721a/ERC721A.sol";
import { AccessControl } from "openzeppelin/contracts/access/AccessControl.sol";
import { Strings } from "openzeppelin/contracts/utils/Strings.sol";
import { DefaultOperatorFilterer } from "operator-filter-registry/DefaultOperatorFilterer.sol";
import { RegistryManager } from "./RegistryManager.sol";

/**
 * <<< nexus-gaming.io >>>
 *
 * @title   Nexus Gaming
 * @notice  Nexus Gaming Lifetime Membership NFT
 * @dev     Seller contracts must be authorized to mint the NFTs via MINTER_ROLE
 * @dev     Adheres to OpenSea filter registry for royalty compliance
 * @author  Tuxedo Development
 * @custom:developer BowTiedPickle
 * @custom:developer Lumoswiz
 * @custom:developer BowTiedOriole
 */
contract NexusGaming is ERC721A, AccessControl, DefaultOperatorFilterer, RegistryManager {
    // ---------- Libraries ----------
    using Strings for uint256;

    // ---------- Roles ----------
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // ---------- Storage ----------

    /// @notice Whether or not the token URI is frozen
    bool public frozenURI;

    /// @notice The base URI for the token
    string public baseURI;

    // ---------- Constructor ----------

    /**
     * @notice  Constructs the Nexus Gaming contract
     * @param   _owner  The owner of the contract
     */
    constructor(address _owner) ERC721A("Nexus Gaming Membership", "NEXUS") RegistryManager(_owner) {
        if (_owner == address(0)) revert NexusGaming__ZeroAddressInvalid();

        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
    }

    // ---------- User Actions ----------

    /**
     * @notice  Mints Nexus Gaming NFTs
     * @param   to      The address to mint the NFTs to
     * @param   amount  The amount of NFTs to mint
     */
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    // ---------- Admin ----------

    /**
     * @notice  Sets the base URI for the token
     * @param   uri     The new base URI
     */
    function setBaseURI(string memory uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (frozenURI) revert NexusGaming__TokenURIFrozen();

        baseURI = uri;

        emit NewBaseURI(uri);
    }

    /**
     * @notice  Freezes the token URI
     */
    function freezeURI() external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (frozenURI) revert NexusGaming__TokenURIFrozen();

        frozenURI = true;

        emit URIFrozen(baseURI);
    }

    // ---------- Overrides ----------

    // ----- ERC-721A -----

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI_ = _baseURI();
        return bytes(baseURI_).length != 0 ? string(abi.encodePacked(baseURI_, _toString(tokenId), ".json")) : "";
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, AccessControl) returns (bool) {
        return AccessControl.supportsInterface(interfaceId) || ERC721A.supportsInterface(interfaceId);
    }

    // ----- OpenSea -----

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // ---------- Events ----------

    event URIFrozen(string indexed finalURI);

    event NewBaseURI(string indexed newBaseURI);

    // ---------- Errors ----------

    error NexusGaming__ZeroAddressInvalid();

    error NexusGaming__TokenURIFrozen();
}