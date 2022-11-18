// SPDX-License-Identifier: MIT

/* solhint-disable */
pragma solidity 0.8.9;

interface IEllipsisRegistry {
    function get_n_coins(address pool) external view returns (uint256);

    function get_pool_from_lp_token(address lp) external view returns (address);

    function get_coins(address pool) external view returns (address[4] memory);
}