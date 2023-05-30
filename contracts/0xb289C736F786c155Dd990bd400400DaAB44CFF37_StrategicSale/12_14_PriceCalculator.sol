// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

abstract contract PriceCalculator {
    AggregatorV3Interface public immutable priceFeed;

    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    /**
     * @notice View the price of the token in USD
     */
    // solhint-disable-next-line func-name-mixedcase
    function TOKEN_USD_PRICE() public view virtual returns (uint128);

    /**
     * @notice View the number of decimals (precision) for `TOKEN_USD_PRICE`
     */
    // solhint-disable-next-line func-name-mixedcase
    function TOKEN_USD_PRICE_DECIMALS() public view virtual returns (uint8);

    /**
     * @notice Converts an ETH value to tokens
     * @param _eth, the value to convert
     */
    function convertEthToTokens(uint128 _eth) internal view returns (uint128) {
        return convertEthToTokensAtPrice(_eth, TOKEN_USD_PRICE());
    }

    /**
     * @notice Converts an ETH value to tokens
     * @dev /!\ The result has 18 decimals
     * @param _eth, the value to convert
     * @param _tokenUsdPrice, the price of the token in USD
     * @return Token amount for _eth at _tokenUsdPrice USD per token (18 decimals)
     */
    function convertEthToTokensAtPrice(
        uint128 _eth,
        uint128 _tokenUsdPrice
    ) internal view returns (uint128) {
        (, int256 price, , , ) = priceFeed.latestRoundData();

        return
            uint128(
                (uint256(price) * _eth * 10 ** TOKEN_USD_PRICE_DECIMALS()) /
                    _tokenUsdPrice /
                    10 ** priceFeed.decimals()
            );
    }

    /**
     * @notice Converts an tokens value to ETH
     * @param _tokens, the value to convert
     */
    function convertTokensToEth(
        uint128 _tokens
    ) internal view returns (uint128) {
        return convertTokensToEthAtPrice(_tokens, TOKEN_USD_PRICE());
    }

    /**
     * @notice Converts an tokens value to ETH
     * @param _tokens, the value to convert
     * @param _tokenUsdPrice, the price of the token in USD
     * @return ETH amount for _tokens at _tokenUsdPrice $ per tokens (18 decimals)
     */
    function convertTokensToEthAtPrice(
        uint128 _tokens,
        uint128 _tokenUsdPrice
    ) internal view returns (uint128) {
        (, int256 price, , , ) = priceFeed.latestRoundData();

        return
            uint128(
                ((uint256(_tokens) * _tokenUsdPrice) *
                    10 ** priceFeed.decimals()) /
                    uint256(price) /
                    10 ** TOKEN_USD_PRICE_DECIMALS()
            );
    }
}