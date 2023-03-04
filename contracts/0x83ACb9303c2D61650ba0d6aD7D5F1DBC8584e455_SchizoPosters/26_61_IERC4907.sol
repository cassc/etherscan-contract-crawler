// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @dev Read-only Interface of ERC4907.
 */
interface IERC4907 is IERC721 {
    /**
     * @dev Returns the user address for `tokenId`.
     * The zero address indicates that there is no user or if the user is expired.
     */
    function userOf(uint256 tokenId) external view returns (address);

    /**
     * @dev Returns the user's expires of `tokenId`.
     */
    function userExpires(uint256 tokenId) external view returns (uint256);
}