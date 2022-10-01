// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title ILockable
/// @dev Interface for the Lockable extension
/// @author filio.eth

interface IERC721Lockable {

    /**
     * @dev Emitted when `id` token is locked, and `unlocker` is stated as unlocking wallet.
     */
    event Lock (address indexed unlocker, uint256 indexed id);

    /**
     * @dev Emitted when `id` token is unlocked.
     */
    event Unlock (uint256 indexed id);

    /**
     * @dev Locks the `id` token and states `unlocker` wallet as unlocker.
     */
    function lock(address unlocker, uint256 id) external;

    /**
     * @dev Unlocks the `id` token.
     */
    function unlock(uint256 id) external;

    /**
     * @dev Returns the wallet, that is stated as unlocking wallet for the `tokenId` token.
     * If address(0) returned, that means token is not locked. Any other result means token is locked.
     */
    function getLocked(uint256 tokenId) external view returns (address);

}