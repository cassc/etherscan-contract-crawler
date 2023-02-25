// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

/**
 * @title ERC-721 Non-Fungible Token Standard, MetaBrands standard
 */
interface IERC721MetaBrands {
    
    /**
     * @dev Returns the minted token Id.
     */
    function mint(address owner) external returns (uint256);

    function burn(uint256 tokenId) external;
}