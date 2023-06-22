// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title ILockable
/// @dev Interface for the Lockable extension

interface IERC721Lockable {

    event Lock (address indexed unlocker, uint256 indexed id);

    event Unlock (uint256 indexed id);

    function lock(address unlocker, uint256 id) external;

    function unlock(uint256 id) external;

    function getLocked(uint256 tokenId) external view returns (address);

}