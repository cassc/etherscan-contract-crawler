// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

//import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "./solmate/ERC721.sol";
import "./Errors.sol";

abstract contract ERC721NonTransferrableUpgradeable is ERC721 {

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        revert TokenTransferDisabled();
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
       revert TokenTransferDisabled();
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual override {
        revert TokenTransferDisabled();
    }

}