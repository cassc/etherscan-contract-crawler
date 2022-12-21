// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

error TokenIsLockedForTransfers();
error AddressIsLockedForTransfers();
error TransfersArePaused();

/**
 * @title ERC721Lockable
 * @author North Technologies
 * @custom:version v1.1
 * @custom:date 30 April 2022
 * @dev ERC721 extention to allow to lock a single token or lock the entire contract from making transfers.
 * Requirements:
 *
 * - The ERC721 contract can not mint on tokenId 0. This is reserved for the wildcard lock.
 * The rationale to use a wildcard lock instead of a seperate boolen is because it saves on contract size and gas.
 *
 * @custom:changelog
 *
 * v1.1
 * - Added the ability to lock on an address so all tokens are locked / unlocked in one transaction
 * - Used Error objects
 * - Removed check for token existing in flipping token lock
 * - Different error for different locks (paused, single token, address)
 *
 */
abstract contract ERC721Lockable is ERC721 {
    mapping(uint256 => bool) private _locked;
    mapping(address => bool) private _addressLocked;

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        if(isLocked(0)) revert TransfersArePaused();
        if(isLocked(tokenId)) revert TokenIsLockedForTransfers();
        if(isAddressLocked(from)) revert AddressIsLockedForTransfers();
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Emitted when the lock is flipped.
     */
    event LockFlipped(uint256 tokenId, bool currentState);
    event AddressLockFlipped(address _address, bool currentState);

    /**
     * @dev Returns true if the token is locked, and false otherwise.
     */
    function isLocked(uint256 tokenId) public view virtual returns (bool) {
        return _locked[tokenId];
    }

    function isAddressLocked(address _address) public view virtual returns (bool) {
        return _addressLocked[_address];
    }

    function _flipLock(uint256 tokenId) internal virtual {
        _locked[tokenId] = !_locked[tokenId];
        emit LockFlipped(tokenId, _locked[tokenId]);
    }

    function _flipAddressLock(address _address) internal virtual {
        _addressLocked[_address] = !_addressLocked[_address];
        emit AddressLockFlipped(_address, _addressLocked[_address]);
    }
}