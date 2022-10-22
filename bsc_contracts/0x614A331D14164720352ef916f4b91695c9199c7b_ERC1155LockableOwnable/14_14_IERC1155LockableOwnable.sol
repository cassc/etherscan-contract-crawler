// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @dev Extension of {ERC1155} that allows diamond owner to lock tokens.
 */
interface IERC1155LockableOwnable {
    function lockByOwner(
        address account,
        uint256 id,
        uint256 amount
    ) external;

    function lockByOwner(
        address[] memory accounts,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;

    function unlockByOwner(
        address account,
        uint256 id,
        uint256 amount
    ) external;

    function unlockByOwner(
        address[] memory accounts,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;
}