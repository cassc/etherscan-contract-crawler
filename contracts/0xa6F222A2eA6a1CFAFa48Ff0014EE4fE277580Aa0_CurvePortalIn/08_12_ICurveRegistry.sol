/// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

interface ICurveRegistry {
    function get_coins(address _pool) external view returns (address[8] memory);

    function get_n_coins(address _pool) external view returns (uint256);
}