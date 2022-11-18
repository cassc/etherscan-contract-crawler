// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title IERC721Initializer
 * @author Limit Break, Inc.
 * @notice Allows cloneable contracts to include OpenZeppelin ERC721 functionality.
 * @dev See https://eips.ethereum.org/EIPS/eip-1167 for details.
 */
interface IERC721Initializer is IERC721 {

    /**
     * @notice Initializes parameters of {ERC721} contracts
     */
    function initializeERC721(string memory name_, string memory symbol_) external;
}