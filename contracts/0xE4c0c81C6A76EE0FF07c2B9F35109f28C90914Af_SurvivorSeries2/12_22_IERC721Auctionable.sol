// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "erc721a/contracts/IERC721A.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Auctionable {
    /**
     * @notice Owner can mint to specified address
     *
     * @param to The address to mint to.
     * @param quantity The number of tokens to mint
     */
    function ownerMint(address to, uint256 quantity) external;
}