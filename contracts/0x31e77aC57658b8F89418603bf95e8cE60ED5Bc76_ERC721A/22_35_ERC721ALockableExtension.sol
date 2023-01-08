// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../../common/Errors.sol";
import "./ERC721ALockableInternal.sol";
import "./IERC721LockableExtension.sol";

abstract contract ERC721ALockableExtension is IERC721LockableExtension, ERC721ALockableInternal {
    function locked(uint256 tokenId) public view virtual returns (bool) {
        return super._locked(tokenId);
    }

    function locked(uint256[] memory ticketTokenIds) public view virtual returns (bool[] memory states) {
        states = new bool[](ticketTokenIds.length);

        for (uint256 i = 0; i < ticketTokenIds.length; i++) {
            states[i] = _locked(ticketTokenIds[i]);
        }

        return states;
    }

    /**
     * @inheritdoc IERC721LockableExtension
     */
    function lockByFacet(uint256 id) public virtual override {
        if (address(this) != msg.sender) {
            revert ErrSenderIsNotSelf();
        }

        _lock(id);
    }

    /**
     * @inheritdoc IERC721LockableExtension
     */
    function lockByFacet(uint256[] memory ids) public virtual override {
        if (address(this) != msg.sender) {
            revert ErrSenderIsNotSelf();
        }
        for (uint256 i = 0; i < ids.length; i++) {
            _lock(ids[i]);
        }
    }

    /**
     * @inheritdoc IERC721LockableExtension
     */
    function unlockByFacet(uint256 id) public virtual override {
        if (address(this) != msg.sender) {
            revert ErrSenderIsNotSelf();
        }
        _unlock(id);
    }

    /**
     * @inheritdoc IERC721LockableExtension
     */
    function unlockByFacet(uint256[] memory ids) public virtual override {
        if (address(this) != msg.sender) {
            revert ErrSenderIsNotSelf();
        }
        for (uint256 i = 0; i < ids.length; i++) {
            _unlock(ids[i]);
        }
    }
}