// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ICurveRegistry {
    function get_n_coins(address lp) external view returns (uint256);

    function get_coins(address pool) external view returns (address[8] memory);

    function get_underlying_coins(address pool) external view returns (address[8] memory);

    function get_pool_from_lp_token(address lp) external view returns (address);

    function is_meta(address pool) external view returns (bool);
}