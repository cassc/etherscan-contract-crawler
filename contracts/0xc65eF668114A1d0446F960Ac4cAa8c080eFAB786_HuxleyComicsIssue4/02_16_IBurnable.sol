// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "erc721a/contracts/IERC721A.sol";

/**
 * @dev Interface of an ERC721ABurnable compliant contract.
 */
interface IBurnable is IERC721A {
    /**
     * @dev Burns `tokenId`. See {ERC721A-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burnBatch(uint256[] memory _tokenIds) external;
}