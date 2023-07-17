// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface ICurveMetaRegistry {
    event CommitNewAdmin(uint256 indexed deadline, address indexed admin);
    event NewAdmin(address indexed admin);

    function add_registry_handler(address _registry_handler) external;

    function update_registry_handler(uint256 _index, address _registry_handler) external;

    function get_registry_handlers_from_pool(
        address _pool
    ) external view returns (address[10] memory);

    function get_base_registry(address registry_handler) external view returns (address);

    function find_pool_for_coins(address _from, address _to) external view returns (address);

    function find_pool_for_coins(
        address _from,
        address _to,
        uint256 i
    ) external view returns (address);

    function find_pools_for_coins(
        address _from,
        address _to
    ) external view returns (address[] memory);

    function get_admin_balances(address _pool) external view returns (uint256[8] memory);

    function get_admin_balances(
        address _pool,
        uint256 _handler_id
    ) external view returns (uint256[8] memory);

    function get_balances(address _pool) external view returns (uint256[8] memory);

    function get_balances(
        address _pool,
        uint256 _handler_id
    ) external view returns (uint256[8] memory);

    function get_base_pool(address _pool) external view returns (address);

    function get_base_pool(address _pool, uint256 _handler_id) external view returns (address);

    function get_coin_indices(
        address _pool,
        address _from,
        address _to
    ) external view returns (int128, int128, bool);

    function get_coin_indices(
        address _pool,
        address _from,
        address _to,
        uint256 _handler_id
    ) external view returns (int128, int128, bool);

    function get_coins(address _pool) external view returns (address[8] memory);

    function get_coins(
        address _pool,
        uint256 _handler_id
    ) external view returns (address[8] memory);

    function get_decimals(address _pool) external view returns (uint256[8] memory);

    function get_decimals(
        address _pool,
        uint256 _handler_id
    ) external view returns (uint256[8] memory);

    function get_fees(address _pool) external view returns (uint256[10] memory);

    function get_fees(
        address _pool,
        uint256 _handler_id
    ) external view returns (uint256[10] memory);

    function get_gauge(address _pool) external view returns (address);

    function get_gauge(address _pool, uint256 gauge_idx) external view returns (address);

    function get_gauge(
        address _pool,
        uint256 gauge_idx,
        uint256 _handler_id
    ) external view returns (address);

    function get_gauge_type(address _pool) external view returns (int128);

    function get_gauge_type(address _pool, uint256 gauge_idx) external view returns (int128);

    function get_gauge_type(
        address _pool,
        uint256 gauge_idx,
        uint256 _handler_id
    ) external view returns (int128);

    function get_lp_token(address _pool) external view returns (address);

    function get_lp_token(address _pool, uint256 _handler_id) external view returns (address);

    function get_n_coins(address _pool) external view returns (uint256);

    function get_n_coins(address _pool, uint256 _handler_id) external view returns (uint256);

    function get_n_underlying_coins(address _pool) external view returns (uint256);

    function get_n_underlying_coins(
        address _pool,
        uint256 _handler_id
    ) external view returns (uint256);

    function get_pool_asset_type(address _pool) external view returns (uint256);

    function get_pool_asset_type(
        address _pool,
        uint256 _handler_id
    ) external view returns (uint256);

    function get_pool_from_lp_token(address _token) external view returns (address);

    function get_pool_from_lp_token(
        address _token,
        uint256 _handler_id
    ) external view returns (address);

    function get_pool_params(address _pool) external view returns (uint256[20] memory);

    function get_pool_params(
        address _pool,
        uint256 _handler_id
    ) external view returns (uint256[20] memory);

    function get_pool_name(address _pool) external view returns (string memory);

    function get_pool_name(
        address _pool,
        uint256 _handler_id
    ) external view returns (string memory);

    function get_underlying_balances(address _pool) external view returns (uint256[8] memory);

    function get_underlying_balances(
        address _pool,
        uint256 _handler_id
    ) external view returns (uint256[8] memory);

    function get_underlying_coins(address _pool) external view returns (address[8] memory);

    function get_underlying_coins(
        address _pool,
        uint256 _handler_id
    ) external view returns (address[8] memory);

    function get_underlying_decimals(address _pool) external view returns (uint256[8] memory);

    function get_underlying_decimals(
        address _pool,
        uint256 _handler_id
    ) external view returns (uint256[8] memory);

    function get_virtual_price_from_lp_token(address _token) external view returns (uint256);

    function get_virtual_price_from_lp_token(
        address _token,
        uint256 _handler_id
    ) external view returns (uint256);

    function is_meta(address _pool) external view returns (bool);

    function is_meta(address _pool, uint256 _handler_id) external view returns (bool);

    function is_registered(address _pool) external view returns (bool);

    function is_registered(address _pool, uint256 _handler_id) external view returns (bool);

    function pool_count() external view returns (uint256);

    function pool_list(uint256 _index) external view returns (address);

    function address_provider() external view returns (address);

    function owner() external view returns (address);

    function get_registry(uint256 arg0) external view returns (address);

    function registry_length() external view returns (uint256);
}