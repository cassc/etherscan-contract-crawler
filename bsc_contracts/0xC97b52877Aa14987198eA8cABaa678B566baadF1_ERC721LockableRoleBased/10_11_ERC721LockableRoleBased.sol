// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../../common/Errors.sol";
import "../../../../access/roles/AccessControlInternal.sol";
import "../../extensions/lockable/IERC721LockableExtension.sol";
import "./IERC721LockableRoleBased.sol";

/**
 * @title ERC721 - Lock as role
 * @notice Allow locking tokens by any sender who has the LOCKER_ROLE.
 *
 * @custom:type eip-2535-facet
 * @custom:category NFTs
 * @custom:required-dependencies IERC721LockableExtension
 * @custom:provides-interfaces IERC721LockableRoleBased
 */
contract ERC721LockableRoleBased is IERC721LockableRoleBased, AccessControlInternal {
    bytes32 public constant LOCKER_ROLE = keccak256("LOCKER_ROLE");

    /**
     * @inheritdoc IERC721LockableRoleBased
     */
    function lockByRole(uint256 id) external virtual onlyRole(LOCKER_ROLE) {
        IERC721LockableExtension(address(this)).lockByFacet(id);
    }

    /**
     * @inheritdoc IERC721LockableRoleBased
     */
    function lockByRole(uint256[] memory ids) external virtual onlyRole(LOCKER_ROLE) {
        IERC721LockableExtension(address(this)).lockByFacet(ids);
    }

    /**
     * @inheritdoc IERC721LockableRoleBased
     */
    function unlockByRole(uint256 id) external virtual onlyRole(LOCKER_ROLE) {
        IERC721LockableExtension(address(this)).unlockByFacet(id);
    }

    /**
     * @inheritdoc IERC721LockableRoleBased
     */
    function unlockByRole(uint256[] memory ids) external virtual onlyRole(LOCKER_ROLE) {
        IERC721LockableExtension(address(this)).unlockByFacet(ids);
    }
}