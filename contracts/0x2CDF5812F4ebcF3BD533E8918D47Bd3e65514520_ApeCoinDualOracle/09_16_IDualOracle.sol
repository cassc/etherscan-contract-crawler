// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IDualOracle is IERC165 {
    function ORACLE_PRECISION() external view returns (uint256);

    function baseToken() external view returns (address);

    function decimals() external pure returns (uint8);

    function getPrices() external view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh);

    function name() external pure returns (string memory);

    function oracleType() external view returns (uint256);

    function quoteToken() external view returns (address);
}