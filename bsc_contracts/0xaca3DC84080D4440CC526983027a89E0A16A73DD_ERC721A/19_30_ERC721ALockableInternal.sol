// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

import "../../base/ERC721ABaseInternal.sol";
import "./ERC721LockableStorage.sol";
import "./IERC721LockableInternal.sol";

abstract contract ERC721ALockableInternal is IERC721LockableInternal, ERC721ABaseInternal {
    using BitMaps for BitMaps.BitMap;
    using ERC721LockableStorage for ERC721LockableStorage.Layout;

    function _locked(uint256 tokenId) internal view virtual returns (bool) {
        return ERC721LockableStorage.layout().lockedTokens.get(tokenId);
    }

    /* INTERNAL */

    function _lock(uint256 tokenId) internal virtual {
        ERC721LockableStorage.layout().lockedTokens.set(tokenId);
        emit Locked(tokenId);
    }

    function _unlock(uint256 tokenId) internal virtual {
        ERC721LockableStorage.layout().lockedTokens.unset(tokenId);
        emit Unlocked(tokenId);
    }

    /**
     * @dev See {ERC721A-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        if (from != address(0)) {
            for (uint256 i = 0; i < quantity; i++) {
                if (_locked(startTokenId + i)) {
                    revert ErrTokenLocked(startTokenId + i);
                }
            }
        }

        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}