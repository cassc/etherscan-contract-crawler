// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ICurveFactoryRegistry {
    function get_n_coins(address lp) external view returns (uint256);

    function get_coins(address pool) external view returns (address[4] memory);

    function get_meta_n_coins(address pool) external view returns (uint256, uint256);

    function deploy_plain_pool(
        string memory _name,
        string memory _symbol,
        address[4] memory _coins,
        uint256 _A,
        uint256 _fee,
        uint256 _asset_type,
        uint256 _implementation_idx
    ) external;

    function base_pool_assets(address) external view returns (bool);

    function pool_count() external view returns (uint256);

    function pool_list(uint256) external view returns (address);

    function deploy_metapool(
        address _base_pool,
        string memory _name,
        string memory _symbol,
        address _coin,
        uint256 _A,
        uint256 _fee
    ) external;

    function get_fees(address _pool) external view returns (uint256, uint256);

    function get_balances(address _pool) external view returns (uint256[4] memory);

    function get_underlying_balances(address _pool) external view returns (uint256[4] memory);

    function is_meta(address _pool) external view returns (bool);

    function get_metapool_rates(address _pool) external view returns (uint256[2] memory);

    function find_pool_for_coins(address _from, address _to) external view returns (address _pool);

    function get_coin_indices(
        address _pool,
        address _from,
        address _to
    ) external view returns (int128 i, int128 j, bool _is_underlying);
}