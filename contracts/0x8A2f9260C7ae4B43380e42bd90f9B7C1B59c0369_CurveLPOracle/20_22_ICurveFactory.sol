// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface ICurveFactory {
    function get_n_coins(address _pool) external view returns (uint256);

    function get_decimals(address curvePool_) external view returns (uint256[4] memory);
}