// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./ERC721ALockableExtension.sol";

interface IERC721ARoleBasedLockableExtension {
    function hasRoleBasedLockableExtension() external view returns (bool);
}

/**
 * @dev Extension to allow locking NFTs, for use-cases like staking, without leaving holders wallet, using roles.
 */
abstract contract ERC721ARoleBasedLockableExtension is
    IERC721ARoleBasedLockableExtension,
    ERC721ALockableExtension,
    AccessControl
{
    using BitMaps for BitMaps.BitMap;

    bytes32 public constant LOCKER_ROLE = keccak256("LOCKER_ROLE");

    function __ERC721ARoleBasedLockableExtension_init()
        internal
        onlyInitializing
    {
        __ERC721ARoleBasedLockableExtension_init_unchained();
    }

    function __ERC721ARoleBasedLockableExtension_init_unchained()
        internal
        onlyInitializing
    {
        _registerInterface(
            type(IERC721ARoleBasedLockableExtension).interfaceId
        );
    }

    // ADMIN

    /**
     * Locks token(s) to effectively lock them, while keeping in the same wallet.
     * This mechanism prevents them from being transferred, yet still will show correct owner.
     */
    function lock(uint256 tokenId) public virtual nonReentrant {
        require(hasRole(LOCKER_ROLE, msg.sender), "ERC721/NOT_LOCKER_ROLE");
        _lock(tokenId);
    }

    function lock(uint256[] calldata tokenIds) public virtual nonReentrant {
        require(
            hasRole(LOCKER_ROLE, msg.sender),
            "STAKABLE_ERC721/NOT_LOCKER_ROLE"
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _lock(tokenIds[i]);
        }
    }

    /**
     * Unlocks locked token(s) to be able to transfer.
     */
    function unlock(uint256 tokenId) public virtual nonReentrant {
        require(hasRole(LOCKER_ROLE, msg.sender), "ERC721/NOT_LOCKER_ROLE");
        _unlock(tokenId);
    }

    function unlock(uint256[] calldata tokenIds) public virtual nonReentrant {
        require(
            hasRole(LOCKER_ROLE, msg.sender),
            "STAKABLE_ERC721/NOT_LOCKER_ROLE"
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _unlock(tokenIds[i]);
        }
    }

    // PUBLIC

    function hasRoleBasedLockableExtension()
        public
        view
        virtual
        returns (bool)
    {
        return true;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721ALockableExtension)
        returns (bool)
    {
        return ERC165Storage.supportsInterface(interfaceId);
    }
}