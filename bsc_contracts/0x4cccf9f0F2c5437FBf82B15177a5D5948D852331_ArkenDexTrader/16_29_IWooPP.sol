pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

interface IWooPP {
    function sellBase(
        address baseToken,
        uint256 baseAmount,
        uint256 minQuoteAmount,
        address to,
        address rebateTo
    ) external returns (uint256 quoteAmount);

    function sellQuote(
        address baseToken,
        uint256 quoteAmount,
        uint256 minBaseAmount,
        address to,
        address rebateTo
    ) external returns (uint256 baseAmount);

    function querySellBase(address baseToken, uint256 baseAmount)
        external
        view
        returns (uint256 quoteAmount);

    function querySellQuote(address baseToken, uint256 quoteAmount)
        external
        view
        returns (uint256 baseAmount);
}