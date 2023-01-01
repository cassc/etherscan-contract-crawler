// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @dev Extension of {ERC1155} that allows grantee of LOCKER_ROLE to lock tokens.
 */
interface IERC1155LockableRoleBased {
    function lockByRole(
        address account,
        uint256 id,
        uint256 amount
    ) external;

    function lockByRole(
        address[] memory accounts,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;

    function unlockByRole(
        address account,
        uint256 id,
        uint256 amount
    ) external;

    function unlockByRole(
        address[] memory accounts,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;
}