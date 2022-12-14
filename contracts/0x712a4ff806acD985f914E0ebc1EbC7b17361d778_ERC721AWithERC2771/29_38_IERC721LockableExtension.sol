// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./IERC5192.sol";
import "./IERC721LockableInternal.sol";

/**
 * @dev Based on EIP-5192, extension of {ERC721} that allows other facets from the diamond to lock the tokens.
 */
interface IERC721LockableExtension is IERC5192, IERC721LockableInternal {
    /**
     * @dev Locks `amount` of tokens of `account`, of token type `id`.
     *
     * Requirements:
     *
     * - the caller must be diamond itself (other facets).
     */
    function lockByFacet(uint256 id) external;

    function lockByFacet(uint256[] memory ids) external;

    /**
     * @dev Un-locks `amount` of tokens of `account`, of token type `id`.
     *
     * Requirements:
     *
     * - the caller must be diamond itself (other facets).
     */
    function unlockByFacet(uint256 id) external;

    function unlockByFacet(uint256[] memory ids) external;
}