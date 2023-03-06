// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IDODOV2 {
    function sellBase(address to) external returns (uint256 receiveQuoteAmount);

    function sellQuote(address to) external returns (uint256 receiveBaseAmount);

    function getVaultReserve()
        external
        view
        returns (uint256 baseReserve, uint256 quoteReserve);

    function _BASE_TOKEN_() external view returns (address);

    function _QUOTE_TOKEN_() external view returns (address);
}