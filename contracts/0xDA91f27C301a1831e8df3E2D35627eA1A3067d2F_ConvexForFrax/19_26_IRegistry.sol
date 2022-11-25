// SPDX-License-Identifier: MIT
/* solhint-disable */
pragma solidity 0.8.9;

interface IRegistry {
    function get_pool_from_lp_token() external view returns (address);

    function get_lp_token(address pool) external view returns (address);

    function get_n_coins(address pool) external view returns (uint256[2] memory);

    function get_underlying_coins(address pool) external view returns (address[8] memory);

    function get_underlying_decimals(address pool) external view returns (uint256[8] memory);

    function get_gauges(address pool) external view returns (address[10] memory);
}