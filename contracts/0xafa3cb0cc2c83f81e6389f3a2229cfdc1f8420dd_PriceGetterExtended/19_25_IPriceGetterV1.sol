// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

/**
 * @title IPriceGetterV1
 * @dev This is the original interface for the PriceGetter contract for backward compatibility.
 */
interface IPriceGetterV1 {
    function DECIMALS() external view returns (uint256);

    function FACTORY() external view returns (address);

    function INITCODEHASH() external view returns (bytes32);

    function getLPPrice(address token, uint256 _decimals) external view returns (uint256);

    function getLPPrices(address[] calldata tokens, uint256 _decimals) external view returns (uint256[] memory prices);

    function getNativePrice() external view returns (uint256);

    function getPrice(address token, uint256 _decimals) external view returns (uint256);

    function getPrices(address[] calldata tokens, uint256 _decimals) external view returns (uint256[] memory prices);

    function getRawPrice(address token) external view returns (uint256);

    function getRawPrices(address[] calldata tokens) external view returns (uint256[] memory prices);
}