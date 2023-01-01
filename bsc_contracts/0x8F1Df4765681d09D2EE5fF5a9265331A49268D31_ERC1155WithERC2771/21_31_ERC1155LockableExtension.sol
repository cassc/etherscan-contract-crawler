// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../../common/Errors.sol";
import "./ERC1155LockableInternal.sol";
import "./IERC1155LockableExtension.sol";

abstract contract ERC1155LockableExtension is IERC1155LockableExtension, ERC1155LockableInternal {
    function locked(address account, uint256 tokenId) public view virtual returns (uint256) {
        return super._locked(account, tokenId);
    }

    function locked(address account, uint256[] calldata ticketTokenIds) public view virtual returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](ticketTokenIds.length);

        for (uint256 i = 0; i < ticketTokenIds.length; i++) {
            amounts[i] = _locked(account, ticketTokenIds[i]);
        }

        return amounts;
    }

    /**
     * @inheritdoc IERC1155LockableExtension
     */
    function lockByFacet(
        address account,
        uint256 id,
        uint256 amount
    ) public virtual override {
        if (address(this) != msg.sender) {
            revert ErrSenderIsNotSelf();
        }

        _lock(account, id, amount);
    }

    /**
     * @inheritdoc IERC1155LockableExtension
     */
    function lockByFacet(
        address[] memory accounts,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public virtual override {
        if (address(this) != msg.sender) {
            revert ErrSenderIsNotSelf();
        }

        require(accounts.length == ids.length && accounts.length == amounts.length, "INVALID_ARRAY_LENGTH");

        for (uint256 i = 0; i < accounts.length; i++) {
            _lock(accounts[i], ids[i], amounts[i]);
        }
    }

    /**
     * @inheritdoc IERC1155LockableExtension
     */
    function unlockByFacet(
        address account,
        uint256 id,
        uint256 amount
    ) public virtual override {
        if (address(this) != msg.sender) {
            revert ErrSenderIsNotSelf();
        }

        _unlock(account, id, amount);
    }

    /**
     * @inheritdoc IERC1155LockableExtension
     */
    function unlockByFacet(
        address[] memory accounts,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public virtual override {
        if (address(this) != msg.sender) {
            revert ErrSenderIsNotSelf();
        }

        require(accounts.length == ids.length && accounts.length == amounts.length, "INVALID_ARRAY_LENGTH");

        for (uint256 i = 0; i < accounts.length; i++) {
            _unlock(accounts[i], ids[i], amounts[i]);
        }
    }
}