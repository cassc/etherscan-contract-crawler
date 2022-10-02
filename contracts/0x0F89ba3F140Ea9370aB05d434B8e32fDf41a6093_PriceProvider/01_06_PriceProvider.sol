// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IPriceOracle.sol";
import "../interfaces/IPriceProvider.sol";
import "../interfaces/IERC20Detailed.sol";

contract PriceProvider is IPriceProvider, Ownable {

    uint private constant PRECISION = 1 ether;

    /// Maps a token address to an oracle
    mapping(address => address) public priceOracle;

    /**
     * @dev Constructor for the price oracle
     */
    constructor() {}

    function setTokenOracle(address token, address oracle) external onlyOwner {
        priceOracle[token] = oracle;

        emit SetTokenOracle(token, oracle);
    }

    function getSafePrice(address token) external view override returns (uint256) {
        require(priceOracle[token] != address(0), "UNSUPPORTED");

        return IPriceOracle(priceOracle[token]).getSafePrice(token);
    }

    function getCurrentPrice(address token) external view override returns (uint256) {
        require(priceOracle[token] != address(0), "UNSUPPORTED");

        return IPriceOracle(priceOracle[token]).getCurrentPrice(token);
    }

    function updateSafePrice(address token) external override returns (uint256) {
        require(priceOracle[token] != address(0), "UNSUPPORTED");

        return IPriceOracle(priceOracle[token]).updateSafePrice(token);
    }

    //get the value of token based on the price of quote
    function getValueOfAsset(address token, address quote) external view override returns (uint safePrice) {
        // Both token and quote must have oracles
        address tokenOracle = priceOracle[token];
        address quoteOracle = priceOracle[quote];
        require(tokenOracle != address(0), "UNSUPPORTED");
        require(quoteOracle != address(0), "UNSUPPORTED");

        uint tokenPriceToEth = IPriceOracle(tokenOracle).getSafePrice(token);
        uint quotePriceToEth = IPriceOracle(quoteOracle).getSafePrice(quote);
        // Prices should always be in 1E18 precision
        safePrice = PRECISION * tokenPriceToEth / quotePriceToEth;

        uint tokenDecimals = IERC20Detailed(token).decimals();
        uint quoteDecimals = IERC20Detailed(quote).decimals();
        if(tokenDecimals == quoteDecimals) {
            return safePrice;
        } 
        if(tokenDecimals > quoteDecimals) {
            // Adjust down by tokenDecimals - quoteDecimals
            safePrice /= (10 ** (tokenDecimals - quoteDecimals));
        } else {
            safePrice *= (10 ** (quoteDecimals - tokenDecimals));
        }
    }

    function tokenHasOracle(address token) public view override returns (bool hasOracle) {
        hasOracle = priceOracle[token] != address(0);
    }

    function pairHasOracle(address token, address quote) external view override returns (bool hasOracle) {
        hasOracle = tokenHasOracle(token) && tokenHasOracle(quote);
    }

}