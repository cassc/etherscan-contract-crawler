// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC721Burnable} from "./../interfaces/IERC721Burnable.sol";
import {ERC721Storage} from "./../libraries/ERC721Storage.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/// @title ERC721 Non-Fungible Token Standard, optional extension: Burnable (proxiable version).
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC721 (Non-Fungible Token Standard).
abstract contract ERC721BurnableBase is Context, IERC721Burnable {
    using ERC721Storage for ERC721Storage.Layout;

    /// @inheritdoc IERC721Burnable
    function burnFrom(address from, uint256 tokenId) external virtual override {
        ERC721Storage.layout().burnFrom(_msgSender(), from, tokenId);
    }

    /// @inheritdoc IERC721Burnable
    function batchBurnFrom(address from, uint256[] calldata tokenIds) external virtual override {
        ERC721Storage.layout().batchBurnFrom(_msgSender(), from, tokenIds);
    }
}