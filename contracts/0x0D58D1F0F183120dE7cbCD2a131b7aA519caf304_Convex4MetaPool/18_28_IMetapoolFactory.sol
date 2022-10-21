// SPDX-License-Identifier: MIT

/* solhint-disable func-name-mixedcase*/
pragma solidity 0.8.9;

interface IMetapoolFactory {
    function get_underlying_coins(address pool) external view returns (address[8] memory);

    function get_underlying_decimals(address pool) external view returns (uint256[8] memory);

    function get_coins(address pool) external view returns (address[4] memory);

    function get_n_coins(address pool) external view returns (uint256);

    function get_meta_n_coins(address pool) external view returns (uint256[2] memory);

    function get_decimals(address pool) external view returns (uint256[4] memory);

    function get_gauge(address pool) external view returns (address);

    function is_meta(address pool) external view returns (bool);
}