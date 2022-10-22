// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @dev Extension of {ERC721} that allows diamond owner to lock tokens.
 */
interface IERC721LockableOwnable {
    function lockByOwner(uint256 id) external;

    function lockByOwner(uint256[] memory ids) external;

    function unlockByOwner(uint256 id) external;

    function unlockByOwner(uint256[] memory ids) external;
}