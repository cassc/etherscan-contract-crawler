// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INFTKEYMarketplaceRoyalty {
    /**
     * @dev Royalty fee
     * @param erc721Address to read royalty
     */
    function setRoyalty(
        address erc721Address,
        address recipient,
        uint256 feeFraction
    ) external;
}