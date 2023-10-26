pragma solidity ^0.8.10;

interface ICurveBasePool {
    function balances(uint256 arg0) external view returns (uint256);
    function calc_token_amount(uint256[3] memory amounts, bool deposit) external view returns (uint256);
    function calc_withdraw_one_coin(uint256, int128) external view returns (uint256);
    function calc_withdraw_one_coin(uint256, uint256) external view returns (uint256);
    function coins(uint256 arg0) external view returns (address);
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
    function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns (uint256);
    function get_virtual_price() external view returns (uint256);
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_amount) external;
    function remove_liquidity_one_coin(uint256 _token_amount, uint256 i, uint256 min_amount) external;
}

interface ICurveMetaPool {
    function calc_withdraw_one_coin(address _pool, uint256 _token_amount, int128 i) external view returns (uint256);
    function calc_withdraw_one_coin(address _pool, uint256 _token_amount, uint256 i) external view returns (uint256);
    function remove_liquidity_one_coin(address _pool, uint256 _token_amount, int128 i, uint256 min_amount) external;
    function remove_liquidity_one_coin(address _pool, uint256 _token_amount, uint256 i, uint256 min_amount) external;
}

interface IPool2 is ICurveBasePool {
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external payable;
}

interface IPool3 is ICurveBasePool {
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount) external payable;
}

interface IPool4 is ICurveBasePool {
    function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount) external payable;
}

interface IPool5 is ICurveBasePool {
    function add_liquidity(uint256[5] memory amounts, uint256 min_mint_amount) external payable;
}

interface IPoolUnderlying2 is ICurveBasePool {
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount, bool use_underlying) external payable;
}

interface IPoolUnderlying3 is ICurveBasePool {
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount, bool use_underlying) external payable;
}

interface IPoolUnderlying4 is ICurveBasePool {
    function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount, bool use_underlying) external payable;
}

interface IPoolUnderlying5 is ICurveBasePool {
    function add_liquidity(uint256[5] memory amounts, uint256 min_mint_amount, bool use_underlying) external payable;
}

interface IPoolFactory2 is ICurveBasePool {
    function add_liquidity(address pool, uint256[2] memory amounts, uint256 min_mint_amount) external payable;
}

interface IPoolFactory3 is ICurveBasePool {
    function add_liquidity(address pool, uint256[3] memory amounts, uint256 min_mint_amount) external payable;
}

interface IPoolFactory4 is ICurveBasePool {
    function add_liquidity(address pool, uint256[4] memory amounts, uint256 min_mint_amount) external payable;
}

interface IPoolFactory5 is ICurveBasePool {
    function add_liquidity(address pool, uint256[5] memory amounts, uint256 min_mint_amount) external payable;
}

interface IPoolWithEth {
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external payable;
}