// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC721O.sol";

/**
 * @dev Implementation of ERC721-O (Omnichain Non-Fungible Token standard) SafeRemote Extension.
 * Using the `safeSetRemote` mechanism to avoid potential fund loss during remote changes
 */
abstract contract ERC721OSafeRemote is ERC721O {
    /**
     * @dev Emitted when moving token to `chainId` chain is paused
     */
    event Paused(uint16 chainId);

    /**
     * @dev Emitted when moving token to `chainId` on `chainId` chain is unpaused
     */
    event Unpaused(uint16 chainId);

    // Mapping from chainId to whether move() function is paused
    mapping(uint16 => bool) internal _pauses;

    /**
     * @dev Returns whether moving token to `chainId` chain is paused
     */
    function pauses(uint16 chainId) public view virtual returns (bool) {
        return _pauses[chainId];
    }

    /**
     * @dev See {ERC721_O-_beforeMoveOut}.
     */
    function _beforeMoveOut(
        address, // from
        uint16 dstChainId,
        bytes memory, // to
        uint256 tokenId
    ) internal virtual override {
        require(
            !_pauses[dstChainId],
            "ERC721OSafeRemote: cannot move token to a paused chain"
        );
        _burn(tokenId);
    }

    /**
     * @dev Disallow moving token to `chainId` chain
     *
     * Requirements:
     *
     * - The state is unpaused
     */
    function pauseMove(uint16 chainId) public virtual onlyOwner {
        require(_pauses[chainId] == false, "ERC721OSafeRemote: already paused");
        _pauses[chainId] = true;
    }

    /**
     * @dev Permit moving token to `chainId` chain
     * @notice Only unpause when remote contract on `chainId` has invoked `setRemote()` for current contract, or fund may LOST permanently
     *
     * Requirements:
     *
     * - The state is paused
     */
    function unpauseMove(uint16 chainId) public virtual onlyOwner {
        require(_pauses[chainId] == true, "ERC721OSafeRemote: unpaused");
        _pauses[chainId] = false;
    }
}