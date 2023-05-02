// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IDualOracle is IERC165 {
    function ORACLE_PRECISION() external view returns (uint256);

    function BASE_TOKEN_0() external view returns (address);

    function BASE_TOKEN_0_DECIMALS() external view returns (uint256);

    function BASE_TOKEN_1() external view returns (address);

    function BASE_TOKEN_1_DECIMALS() external view returns (uint256);

    function decimals() external view returns (uint8);

    function getPricesNormalized() external view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh);

    function getPrices() external view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh);

    function name() external view returns (string memory);

    function NORMALIZATION_0() external view returns (int256);

    function NORMALIZATION_1() external view returns (int256);

    function QUOTE_TOKEN_0() external view returns (address);

    function QUOTE_TOKEN_0_DECIMALS() external view returns (uint256);

    function QUOTE_TOKEN_1() external view returns (address);

    function QUOTE_TOKEN_1_DECIMALS() external view returns (uint256);
}