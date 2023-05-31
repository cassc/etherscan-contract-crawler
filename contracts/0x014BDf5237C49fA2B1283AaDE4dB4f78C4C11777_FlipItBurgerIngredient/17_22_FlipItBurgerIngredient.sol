// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { IERC1155 } from "@openzeppelin/contracts/interfaces/IERC1155.sol";
import { ERC1155Burnable } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { ERC2981 } from "@openzeppelin/contracts/token/common/ERC2981.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { IERC1155Mintable } from "./interfaces/IERC1155Mintable.sol";

import { DefaultOperatorFilterer } from "operator-filter-registry/src/DefaultOperatorFilterer.sol";

/**
 *  @title FlipIt ERC1155 token
 *
 *  @notice An implementation of the ERC1155 token in the FlipIt ecosystem.
 */
contract FlipItBurgerIngredient is ERC1155, ERC1155Burnable, ERC2981, AccessControl, IERC1155Mintable, DefaultOperatorFilterer {
    using Strings for uint256;

    //-------------------------------------------------------------------------
    // Constants & Immutables

    bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");

    //--------------------------------------------------------------------------
    // Construction & Initialization

    /// @notice Contract state initialization.
    /// @param uri_ URI for all token types by relying on ID substitution.
    constructor(string memory uri_) ERC1155(uri_) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @notice Updates the base url value.
    /// @param uri_ URI for all token types by relying on ID substitution.
    function setURI(string calldata uri_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(uri_);
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

    /// @inheritdoc IERC1155Mintable
    function mint(address to, uint256 tokenId, uint256 amount, bytes memory data) external onlyRole(MINTER_ROLE) {
        _mint(to, tokenId, amount, data);
    }

    /// @inheritdoc IERC1155Mintable
    function mintBatch(address owner, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external onlyRole(MINTER_ROLE) {
        _mintBatch(owner, ids, amounts, data);
    }

    /// @inheritdoc ERC1155
    function setApprovalForAll(address operator, bool approved) public override(ERC1155, IERC1155) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /// @inheritdoc ERC1155
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override(ERC1155, IERC1155) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, id, amount, data);
    }

    /// @inheritdoc ERC1155
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override(ERC1155, IERC1155) onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /// @inheritdoc ERC1155Burnable
    function burn(address owner, uint256 tokenId, uint256 amount) public override(IERC1155Mintable, ERC1155Burnable) {
        super.burn(owner, tokenId, amount);
    }

    /// @inheritdoc IERC1155Mintable
    function burnBatch(address owner, uint256[] memory ids, uint256[] memory amounts) public override(IERC1155Mintable, ERC1155Burnable) {
        super.burnBatch(owner, ids, amounts);
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view override(IERC165, ERC1155, ERC2981, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @inheritdoc ERC1155
    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(super.uri(tokenId), tokenId.toString(), ".json"));
    }
}