// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @dev Extension of {ERC1155} that tracks supply and defines a max supply cap per token ID.
 */
interface IERC1155SupplyExtension {
    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @dev Maximum amount of tokens possible to exist for a given id.
     */
    function maxSupply(uint256 id) external view returns (uint256);

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) external view returns (bool);
}