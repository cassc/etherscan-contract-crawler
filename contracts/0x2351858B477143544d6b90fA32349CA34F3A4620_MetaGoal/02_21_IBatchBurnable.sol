// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "erc721a/contracts/extensions/ERC721ABurnable.sol";

/**
 * @title BatchBurnable.
 *
 * @dev ERC721A token that can be irreversibly burned (destroyed).
 */
interface IBatchBurnable {
    /**
     * @dev Burns `tokenIds`. See {ERC721A-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenIds` or be an approved operator.
     */
    function batchBurn(uint256[] calldata tokenIds) external;
}