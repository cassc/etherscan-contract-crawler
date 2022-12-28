// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

interface ICurveFactory
{
    function find_pool_for_coins(address from, address to, uint256 index) external view returns (address);
    function deploy_metapool(address base_pool, string memory name, string memory symbol, address token, uint256 A, uint256 fee) external returns (address);
    function get_gauge(address _pool) external view returns (address);
    function deploy_gauge(address _pool) external returns (address);
    function pool_count() external view returns (uint256);
    function pool_list(uint256 index) external view returns (address);
}