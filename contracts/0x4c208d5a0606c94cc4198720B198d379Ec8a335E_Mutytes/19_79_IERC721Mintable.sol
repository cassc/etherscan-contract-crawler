// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC721MintableController } from "./IERC721MintableController.sol";

/**
 * @title ERC721 token minting extension interface
 */
interface IERC721Mintable is IERC721MintableController {
    /**
     * @notice Mint new tokens
     * @param amount The amount to mint
     */
    function mint(uint256 amount) external payable;
}