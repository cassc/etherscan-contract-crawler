// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICurvePool {
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external payable;

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external payable;

    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[5] calldata amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[6] calldata amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[7] calldata amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[8] calldata amounts, uint256 min_mint_amount) external;

    function calc_token_amount(uint256[2] calldata amounts, bool deposit)
        external
        view
        returns (uint256 liquidity);

    function calc_token_amount(uint256[3] calldata amounts, bool deposit)
        external
        view
        returns (uint256 liquidity);

    function calc_token_amount(uint256[4] calldata amounts, bool deposit)
        external
        view
        returns (uint256 liquidity);

    function calc_token_amount(uint256[5] calldata amounts, bool deposit)
        external
        view
        returns (uint256 liquidity);

    function calc_token_amount(uint256[6] calldata amounts, bool deposit)
        external
        view
        returns (uint256 liquidity);

    function calc_token_amount(uint256[7] calldata amounts, bool deposit)
        external
        view
        returns (uint256 liquidity);

    function calc_token_amount(uint256[8] calldata amounts, bool deposit)
        external
        view
        returns (uint256 liquidity);

    function remove_liquidity(uint256 _amount, uint256[2] calldata min_amounts) external;

    function remove_liquidity(uint256 _amount, uint256[3] calldata min_amounts) external;

    function remove_liquidity(uint256 _amount, uint256[4] calldata min_amounts) external;

    function remove_liquidity(uint256 _amount, uint256[5] calldata min_amounts) external;

    function remove_liquidity(uint256 _amount, uint256[6] calldata min_amounts) external;

    function remove_liquidity(uint256 _amount, uint256[7] calldata min_amounts) external;

    function remove_liquidity(uint256 _amount, uint256[8] calldata min_amounts) external;
}