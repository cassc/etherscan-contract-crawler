// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

interface IPriceOracle {
    function _addFeed(
        address base,
        address quote,
        AggregatorV2V3Interface aggregator
    ) external;

    function decimals(address base, address quote)
        external
        view
        returns (uint8);

    function latestRoundData(address base, address quote)
        external
        view
        returns (int256);

    function getUsdEthPrice(uint256 amountIn)
        external
        view
        returns (uint256 amountOut);

    function getEthUsdPrice(uint256 amountIn)
        external
        view
        returns (uint256 amountOut);

    function getPrice(address base, address quote)
        external
        view
        returns (int256);

    function getPriceForAmount(
        address token,
        uint256 amount,
        bool ethPath
    ) external view returns (uint256 amountOut);

    function getPriceTokenUSD(address _base, uint256 amountIn)
        external
        view
        returns (uint256 amountOut);

    function getPriceTokenUSD18Decimals(address _base, uint256 amountIn)
        external
        view
        returns (uint256 amountOut);
}