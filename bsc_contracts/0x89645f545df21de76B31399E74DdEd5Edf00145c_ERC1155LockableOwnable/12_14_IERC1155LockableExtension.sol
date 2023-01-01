// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @dev Extension of {ERC1155} that allows other facets from the diamond to lock the tokens.
 */
interface IERC1155LockableExtension {
    /**
     * @dev Locks `amount` of tokens of `account`, of token type `id`.
     *
     * Requirements:
     *
     * - the caller must be diamond itself (other facets).
     */
    function lockByFacet(
        address account,
        uint256 id,
        uint256 amount
    ) external;

    function lockByFacet(
        address[] memory accounts,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;

    /**
     * @dev Un-locks `amount` of tokens of `account`, of token type `id`.
     *
     * Requirements:
     *
     * - the caller must be diamond itself (other facets).
     */
    function unlockByFacet(
        address account,
        uint256 id,
        uint256 amount
    ) external;

    function unlockByFacet(
        address[] memory accounts,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;
}