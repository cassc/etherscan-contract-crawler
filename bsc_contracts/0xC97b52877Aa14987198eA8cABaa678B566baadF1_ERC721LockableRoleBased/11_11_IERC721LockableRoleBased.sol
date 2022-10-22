// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @dev Extension of {ERC721} that allows grantee of LOCKER_ROLE to lock tokens.
 */
interface IERC721LockableRoleBased {
    function lockByRole(uint256 id) external;

    function lockByRole(uint256[] memory ids) external;

    function unlockByRole(uint256 id) external;

    function unlockByRole(uint256[] memory ids) external;
}