// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import "./IPriceGetterV1.sol";
import "./PriceGetterV2.sol";

/**
DISCLAIMER:
This smart contract is provided for user interface purposes only and is not intended to be used for smart contract logic. 
Any attempt to rely on this code for the execution of a smart contract may result in unexpected behavior, 
errors, or other issues that could lead to financial loss or other damages. 
The user assumes all responsibility and risk for proper usage. 
The developer and associated parties make no warranties and are not liable for any damages incurred.
*/

contract PriceGetterExtended is IPriceGetterV1, PriceGetterV2 {
    /**
     * @dev This contract constructor takes in several parameters which includes the wrapped native token address,
     * an array of addresses for stable USD tokens, an array of addresses for oracle tokens, and an array of addresses
     * for oracles.
     *
     * @param _wNative Address of the wrapped native token
     * @param _defaultFactoryV2 Address of factoryV2
     * @param _defaultFactoryV3 Address of factoryV3
     * @param _stableUsdTokens Array of stable USD token addresses
     * @param _oracleTokens Array of oracle token addresses
     * @param _oracles Array of oracle addresses
     */
    constructor(
        address _wNative,
        IApeFactory _defaultFactoryV2,
        IUniswapV3Factory _defaultFactoryV3,
        address[] memory _stableUsdTokens,
        address[] memory _oracleTokens,
        address[] memory _oracles
    ) PriceGetterV2(_wNative, _defaultFactoryV2, _defaultFactoryV3, _stableUsdTokens, _oracleTokens, _oracles) {}

    function DECIMALS() external pure returns (uint256) {
        return 18;
    }

    function FACTORY() external pure returns (address) {
        return address(0);
    }

    function INITCODEHASH() external pure returns (bytes32) {
        return "";
    }

    /**
     * @dev Returns the price of a specified liquidity pool token.
     * @param token The address of the liquidity pool token.
     * @param _decimals UNUSED, kept for backwards compatibility.
     * @return The price of the liquidity pool token.
     */
    function getLPPrice(address token, uint256 _decimals) external view returns (uint256) {
        return getLPPriceV2(token);
    }

    /**
     * @dev Returns the prices of specified liquidity pool tokens.
     * @param tokens Array of liquidity pool token addresses.
     * @param _decimals UNUSED, kept for backwards compatibility.
     * @return prices Array of liquidity pool token prices.
     */
    function getLPPrices(address[] calldata tokens, uint256 _decimals) external view returns (uint256[] memory prices) {
        return getLPPricesV2(tokens);
    }

    function getNativePrice() external view override returns (uint256) {
        return getNativePrice(Protocol.Both);
    }

    function getETHPrice(uint32 secondsAgo) external view returns (uint256) {
        return getNativePrice(Protocol.Both);
    }

    function getETHPrice() external view returns (uint256) {
        return getNativePrice(Protocol.Both);
    }

    /**
     * @dev Returns the price of the specified token.
     * @param token The address of the token.
     * @param _decimals UNUSED, kept for backwards compatibility.
     * @return The price of the token.
     */
    function getPrice(address token, uint256 _decimals) external view override returns (uint256) {
        return getPrice(token, Protocol.Both);
    }

    function getPrice(address token, uint32 secondsAgo) external view returns (uint256) {
        return getPrice(token, Protocol.Both);
    }

    function getPrices(address[] calldata tokens, uint256 _decimals) external view returns (uint256[] memory prices) {
        return getPrices(tokens, Protocol.Both);
    }

    function getPrices(address[] calldata tokens, uint32 secondsAgo) external view returns (uint256[] memory prices) {
        return getPrices(tokens, Protocol.Both);
    }

    function getRawPrice(address token) external view returns (uint256) {
        return getPrice(token, Protocol.V2);
    }

    /**
     * @dev {see getPrices} Left for backwards compatibility.
     */
    function getRawPrices(address[] calldata tokens) external view returns (uint256[] memory prices) {
        return getPrices(tokens, Protocol.V2);
    }
}