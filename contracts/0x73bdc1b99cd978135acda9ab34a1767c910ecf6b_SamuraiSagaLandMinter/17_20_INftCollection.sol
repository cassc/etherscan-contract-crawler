// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INftCollection {
    /**
     * @dev Returns the current supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the max total supply
     */
    function maxSupply() external view returns (uint256);

    /**
     * @dev Mint NFTs from the NFT contract.
     */
    function mint(address _to, uint256 _tokenId) external;

    /**
     * @dev Mint a batch of NFTs from the NFT contract.
     */
    function mintBatch(address _to, uint256[] calldata _tokenIds) external;
}