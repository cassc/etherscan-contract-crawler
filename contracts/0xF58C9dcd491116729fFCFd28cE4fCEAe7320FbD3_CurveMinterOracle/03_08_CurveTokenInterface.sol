// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface CurveTokenV3Interface {
    function minter() external view returns (address);
}

interface CurveSwapInterface {
    function get_virtual_price() external view returns (uint256);
}

interface CurveLPPriceInterface {
    function lp_price() external view returns (uint256);
}