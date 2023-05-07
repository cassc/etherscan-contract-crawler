// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IPriceFeed {

    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );

    function latestRoundData()
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );

}


library ChainlinkLibrary {

    function convertTokenToToken(
        uint256 amount0,
        uint256 token0Denominator,
        uint256 token1Denominator,
        uint256 price0,
        uint256 price1
    ) internal pure returns (uint256 amount1) {
        amount1 = (amount0 * token1Denominator * price0) / (token0Denominator * price1);
    }

    function convertTokenToUsd(
        uint256 amount,
        uint256 tokenDenominator,
        uint256 price
    ) internal pure returns (uint256 amountUsd) {
        amountUsd = amount * price / tokenDenominator;
    }

    function convertUsdToToken(
        uint256 amountUsd,
        uint256 tokenDenominator,
        uint256 price
    ) internal pure returns (uint256 amount) {
        amount = amountUsd * tokenDenominator / price;
    }

    function convertTokenToToken(
        uint256 amount0,
        uint256 token0Denominator,
        uint256 token1Denominator,
        IPriceFeed oracle0,
        IPriceFeed oracle1
    ) internal view returns (uint256 amount1) {
        uint256 price0 = getPrice(oracle0);
        uint256 price1 = getPrice(oracle1);
        amount1 = (amount0 * token1Denominator * price0) / (token0Denominator * price1);
    }

    function getPrice(IPriceFeed oracle) internal view returns (uint256){
        (uint80 roundID, int256 price, , uint256 timeStamp, uint80 answeredInRound) = oracle.latestRoundData();
        require(answeredInRound >= roundID, "Old data");
        require(timeStamp > 0, "Round not complete");
        return uint256(price);

    }

    function convertTokenToUsd(
        uint256 amount,
        uint256 tokenDenominator,
        IPriceFeed oracle
    ) internal view returns (uint256 amountUsd) {
        amountUsd = amount * getPrice(oracle) / tokenDenominator;
    }

    function convertUsdToToken(
        uint256 amountUsd,
        uint256 tokenDenominator,
        IPriceFeed oracle
    ) internal view returns (uint256 amount) {
        amount = amountUsd * tokenDenominator / getPrice(oracle);
    }
}