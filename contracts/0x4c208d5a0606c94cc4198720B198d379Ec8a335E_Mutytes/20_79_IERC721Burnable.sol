// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC721BurnableController } from "./IERC721BurnableController.sol";

/**
 * @title ERC721 token burning extension interface
 */
interface IERC721Burnable is IERC721BurnableController {
    /**
     * @notice Burn a token
     * @param tokenId The token id
     */
    function burn(uint256 tokenId) external;
}