// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ICurveSwap {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(
        // sUSD pool
        uint256[4] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function add_liquidity(
        // frax/usdc pool
        uint256[2] calldata amounts,
        uint256 deadline
    ) external;

    function add_liquidity(
        //curve 3pool and tri crytpo
        uint256[3] calldata amounts,
        uint256 min_mint_amount
    ) external;


    function add_liquidity(
        //curve tusd frax bp
        address _pool,
        uint256[3] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function calc_token_amount(
        //TUSD FRAX BP
        address _pool, 
        uint256[3] calldata _amounts, 
        bool is_deposit) external view returns (uint256);

    function calc_token_amount(
        //sUSD pool
        uint256[4] memory _amounts, 
        bool is_deposit) external view returns (uint256);
    
    function calc_token_amount(
        //3pool
        uint256[3] memory _amounts,
        bool is_deposit) external view returns (uint256);

    function calc_token_amount(
        //stg-usdc
        uint256[2] calldata _amounts) external view returns (uint256);

    function remove_liquidity(uint256 _amount, uint256[4] calldata min_amounts)
        external;
    
    function remove_liquidity(uint256 _amount, uint256[2] calldata min_amounts)
        external;
    
    function remove_liquidity_imbalance(uint[4] memory, uint) external returns (uint);

    function remove_liquidity_one_coin(
        //sUSD pool
        uint256 _token_amount,
        int128 i,
        uint256 _min_uamount,
        bool donate
    ) external;

    function remove_liquidity_one_coin(
        //FRAX/USDC pool & tricrypto
        uint256 _token_amount,
        int128 i,
        uint256 _min_uamount
    ) external;

    function remove_liquidity_one_coin(
        //TUSD FRAX BP
        address _pool,
        uint256 _token_amount,
        int128 i,
        uint256 _min_uamount
    ) external;

    function calc_withdraw_one_coin(uint256, int128) external view returns (uint);

    function calc_withdraw_one_coin(address, uint256, int128) external view returns (uint);

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;
}