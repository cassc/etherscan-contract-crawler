// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../../../common/Errors.sol";
import "../../../../access/roles/AccessControlInternal.sol";
import "../../extensions/lockable/IERC1155LockableExtension.sol";
import "../../base/ERC1155BaseInternal.sol";
import "./IERC1155LockableRoleBased.sol";

/**
 * @title ERC1155 - Lock as role
 * @notice Allow locking tokens by any sender who has the LOCKER_ROLE.
 *
 * @custom:type eip-2535-facet
 * @custom:category NFTs
 * @custom:required-dependencies IERC1155LockableExtension
 * @custom:provides-interfaces IERC1155LockableRoleBased
 */
contract ERC1155LockableRoleBased is IERC1155LockableRoleBased, AccessControlInternal {
    bytes32 public constant LOCKER_ROLE = keccak256("LOCKER_ROLE");

    /**
     * @inheritdoc IERC1155LockableRoleBased
     */
    function lockByRole(
        address account,
        uint256 id,
        uint256 amount
    ) external virtual onlyRole(LOCKER_ROLE) {
        IERC1155LockableExtension(address(this)).lockByFacet(account, id, amount);
    }

    /**
     * @inheritdoc IERC1155LockableRoleBased
     */
    function lockByRole(
        address[] memory accounts,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external virtual onlyRole(LOCKER_ROLE) {
        IERC1155LockableExtension(address(this)).lockByFacet(accounts, ids, amounts);
    }

    /**
     * @inheritdoc IERC1155LockableRoleBased
     */
    function unlockByRole(
        address account,
        uint256 id,
        uint256 amount
    ) external virtual onlyRole(LOCKER_ROLE) {
        IERC1155LockableExtension(address(this)).unlockByFacet(account, id, amount);
    }

    /**
     * @inheritdoc IERC1155LockableRoleBased
     */
    function unlockByRole(
        address[] memory accounts,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external virtual onlyRole(LOCKER_ROLE) {
        IERC1155LockableExtension(address(this)).unlockByFacet(accounts, ids, amounts);
    }
}