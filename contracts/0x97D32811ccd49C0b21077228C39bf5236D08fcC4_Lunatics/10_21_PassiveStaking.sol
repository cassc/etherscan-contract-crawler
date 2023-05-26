// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";

abstract contract PassiveStaking is ERC721A {
    event Spent(address indexed account, uint256 indexed tokenId, uint256 amount);

    uint256 public constant EARN_RATE = 11574074074075;
    uint256 public startTime;

    // mapping of token to spent points
    mapping(uint256 => uint256) internal _spent;

    // A token's issued points. Used by extensions to "lock" tiers on transfer
    mapping(uint256 => uint256) internal _issued;

    function _setStartTime(uint256 _startTime) internal virtual {
        if (startTime > 0) revert AlreadyInitialized();

        startTime = _startTime;
    }

    function total(uint256 tokenId) public view virtual returns (uint256) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        unchecked {
            return earned(tokenId) + spent(tokenId);
        }
    }

    function spent(uint256 tokenId) public view virtual returns (uint256) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return _spent[tokenId];
    }

    function earned(uint256 tokenId) public view virtual returns (uint256) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        if (startTime == 0 || _blockTime() <= startTime) return 0;

        uint256 ownershipStartTimestamp = _ownershipOf(tokenId).startTimestamp;
        if (ownershipStartTimestamp <= startTime) ownershipStartTimestamp = startTime;

        unchecked {
            uint256 base = (_blockTime() - ownershipStartTimestamp) * EARN_RATE;
            return base + _issued[tokenId] - _spent[tokenId];
        }
    }

    function spendFrom(address from, uint256 tokenId, uint256 amount) public virtual returns (bool) {
        TokenOwnership memory owner = _ownershipOf(tokenId);
        if (msg.sender == owner.addr) revert OwnerShouldNotSpendPoints();
        bool isApprovedOrOwner = (isApprovedForAll(from, msg.sender) || getApproved(tokenId) == msg.sender);

        uint256 earned_ = earned(tokenId);

        if (owner.addr != from) revert SpendFromIncorrectOwner();
        if (!isApprovedOrOwner) revert SpendCallerNotApproved();
        if (amount > earned_) revert NotEnoughPoints();

        unchecked {
            _spent[tokenId] = _spent[tokenId] + (amount);
        }

        emit Spent(from, tokenId, amount);
        return true;
    }

    function _issue(uint256 tokenId, uint256 points) internal {
        _issued[tokenId] = points;
    }

    function _blockTime() internal view returns (uint256) {
        return block.timestamp;
    }

    function _beforeTokenTransfers(address from, address, uint256 startTokenId, uint256) internal virtual override {
        // if minting - no need to reset spent
        if (from == address(0)) return;
        _spent[startTokenId] = 0;
    }
}

error OwnerShouldNotSpendPoints();
error SpendCallerNotApproved();
error SpendFromIncorrectOwner();
error NotEnoughPoints();
error AlreadyInitialized();