// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ICurveFactoryRegistry {
    function get_n_coins(address lp) external view returns (uint256);

    function get_coins(address pool) external view returns (address[4] memory);

    function get_meta_n_coins(address pool) external view returns (uint256, uint256);
}