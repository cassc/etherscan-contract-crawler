// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../DigitalNFTBase.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

/// @notice Developed by DigitalNFT.it (https://digitalnft.it/)
abstract contract DigitalNFT1155Base is ERC1155, ERC2981, DefaultOperatorFilterer, DigitalNFTBase {
    using Strings for uint256;

    // ============================== Fields ============================= //

    /**
     * @dev Returns the token collection name.
     */
    string public name;

    /**
     * @dev Returns the token collection symbol.
     */
    string public symbol;


    // ============================ Functions ============================ //

    // ========================= //
    // === Ovrride Functions === //
    // ========================= //

    /**
     * @dev See {ERC1155-uri}.
     */
    function uri(uint256 tokenID) public view virtual override returns (string memory) {
        return string(abi.encodePacked(super.uri(tokenID), tokenID.toString()));
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from, 
        address to, 
        uint256 tokenId,
        uint256 amount, 
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}