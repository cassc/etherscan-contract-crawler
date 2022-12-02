// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

/************
@title IAtomicPriceAggregator interface
@notice Interface for individual NFT token price oracle.*/

interface IAtomicPriceAggregator {
    // get price of a specific tokenId
    function getTokenPrice(uint256 tokenId) external view returns (uint256);

    // get list of prices for list of tokenIds
    function getTokensPrices(uint256[] calldata _okenIds)
        external
        view
        returns (uint256[] memory);

    // get the sum of prices for list of tokenIds
    function getTokensPricesSum(uint256[] calldata tokenIds)
        external
        view
        returns (uint256);

    function latestAnswer() external view returns (int256);
}