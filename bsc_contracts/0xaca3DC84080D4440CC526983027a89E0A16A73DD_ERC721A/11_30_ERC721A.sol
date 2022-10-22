// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./base/ERC721ABase.sol";

import "./extensions/supply/ERC721ASupplyExtension.sol";
import "./extensions/mintable/ERC721AMintableExtension.sol";
import "./extensions/lockable/ERC721ALockableExtension.sol";
import "./extensions/burnable/ERC721ABurnableExtension.sol";

/**
 * @title ERC721 (A) - Standard
 * @notice Azuki's implementation of standard EIP-721 NFTs with core capabilities of Mintable, Burnable and Lockable.
 *
 * @custom:type eip-2535-facet
 * @custom:category NFTs
 * @custom:provides-interfaces IERC721 IERC721ABase IERC721SupplyExtension IERC721MintableExtension IERC721BurnableExtension IERC721LockableExtension IERC5192
 */
contract ERC721A is
    ERC721ABase,
    ERC721ASupplyExtension,
    ERC721AMintableExtension,
    ERC721ALockableExtension,
    ERC721ABurnableExtension
{
    /**
     * @dev See {ERC721A-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(ERC721ABaseInternal, ERC721ASupplyExtension, ERC721ALockableInternal) {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}