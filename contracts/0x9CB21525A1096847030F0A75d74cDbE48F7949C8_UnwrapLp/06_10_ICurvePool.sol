// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ICurvePool {
    function get_virtual_price() external view returns (uint256 price);
    function remove_liquidity(uint256 _amount, uint256[3] memory min_amounts) external;
    function remove_liquidity(uint256 _amount, uint256[2] memory min_amounts) external;
}