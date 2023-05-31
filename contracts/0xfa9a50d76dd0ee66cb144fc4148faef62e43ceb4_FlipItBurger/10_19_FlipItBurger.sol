// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ERC2981 } from "@openzeppelin/contracts/token/common/ERC2981.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

import { ERC721A } from "erc721a/contracts/ERC721A.sol";
import { IERC721A } from "erc721a/contracts/IERC721A.sol";
import { ERC721ABurnable } from "erc721a/contracts/extensions/ERC721ABurnable.sol";

import { DefaultOperatorFilterer } from "operator-filter-registry/src/DefaultOperatorFilterer.sol";

import { IERC721AMintable } from "./interfaces/IERC721AMintable.sol";

/**
 *  @title FlipIt ERC721 token
 *
 *  @notice An implementation of the ERC721 token in the FlipIt ecosystem.
 */
contract FlipItBurger is ERC721A, ERC721ABurnable, ERC2981, AccessControl, IERC721AMintable, DefaultOperatorFilterer {
    using Strings for uint256;

    //-------------------------------------------------------------------------
    // Constants & Immutables

    bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @notice Ensures that each token has an associated asset from a defined set.
    uint256 internal constant TOKEN_URI_DENOMINATOR = 22;

    //-------------------------------------------------------------------------
    // Config

    string internal baseURI;

    //-------------------------------------------------------------------------
    // Events

    /// @notice Event emitted when base url has been updated.
    /// @param baseURI_ The value of the new base url.
    event BaseURIUpdated(string baseURI_);

    //-------------------------------------------------------------------------
    // Errors

    /// @notice The token with given id does not exist.
    /// @param tokenId Id of the token.
    error TokenNotExists(uint256 tokenId);

    //--------------------------------------------------------------------------
    // Construction & Initialization

    /// @notice Contract state initialization.
    /// @param name_ ERC721 name of the token.
    /// @param symbol_ ERC721 symbol of the token.
    /// @param baseURI_ Initial base url for computing tokenURI.
    constructor(string memory name_, string memory symbol_, string memory baseURI_) ERC721A(name_, symbol_) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        baseURI = baseURI_;
    }

    /// @notice Updates the base url value.
    /// @param baseURI_ Base url for computing tokenURI.
    function updateBaseURI(string calldata baseURI_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = baseURI_;

        emit BaseURIUpdated(baseURI_);
    }

    /// @notice Sets the royalty information that all ids in this contract will default to.
    /// @param receiver Address of the receiver.
    /// @param feeNumerator Value of the fee numerator.
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /// @notice Removes default royalty information.
    function deleteDefaultRoyalty() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _deleteDefaultRoyalty();
    }

    /// @notice Sets the royalty information for a specific token id, overriding the global default.
    /// @param tokenId Id of the token.
    /// @param receiver Address of the receiver.
    /// @param feeNumerator Value of the fee numerator.
    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /// @notice Resets royalty information for the token id back to the global default.
    /// @param tokenId Id of the token.
    function resetTokenRoyalty(uint256 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _resetTokenRoyalty(tokenId);
    }

    /// @inheritdoc IERC721AMintable
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    /// @inheritdoc ERC721A
    function setApprovalForAll(address operator, bool approved) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /// @inheritdoc ERC721A
    function approve(address operator, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /// @inheritdoc ERC721A
    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /// @inheritdoc ERC721A
    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /// @inheritdoc ERC721A
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /// @inheritdoc ERC721A
    /// @dev Throws error if token with given id does not exist.
    function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert TokenNotExists(tokenId);

        string memory baseURI_ = _baseURI();

        if (bytes(baseURI_).length <= 0) return "";

        uint256 denominatedTokenId = tokenId % TOKEN_URI_DENOMINATOR;

        return string(abi.encodePacked(baseURI_, (denominatedTokenId == 0 ? TOKEN_URI_DENOMINATOR : denominatedTokenId).toString(), ".json"));
    }

    /// @inheritdoc ERC721A
    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, IERC721A, ERC2981, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @inheritdoc ERC721A
    function _burn(uint256 tokenId, bool approvalCheck) internal override {
        super._burn(tokenId, approvalCheck);
        _resetTokenRoyalty(tokenId);
    }

    /// @inheritdoc ERC721A
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // @inheritdoc ERC721A
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}