// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ICurveSwap {

    function calc_token_amount(uint256[2] calldata _amounts) external returns (uint256 amount);
    function calc_token_amount(uint256[3] calldata _amounts) external returns (uint256 amount);
    function calc_token_amount(uint256[4] calldata _amounts) external returns (uint256 amount);
    function calc_token_amount(uint256[5] calldata _amounts) external returns (uint256 amount);

    function calc_token_amount(uint256[2] calldata _amounts, bool _is_deposit) external returns (uint256 amount);
    function calc_token_amount(uint256[3] calldata _amounts, bool _is_deposit) external returns (uint256 amount);
    function calc_token_amount(uint256[4] calldata _amounts, bool _is_deposit) external returns (uint256 amount);
    function calc_token_amount(uint256[5] calldata _amounts, bool _is_deposit) external returns (uint256 amount);

    function calc_withdraw_one_coin(uint256 _tokenAmount, int128 _index) external view returns (uint256);
    function calc_withdraw_one_coin(uint256 _tokenAmount, uint256 _index) external view returns (uint256);

    function coins(uint256 _arg0) external view returns (address);

    // Standard Curve pool (e.g. https://arbiscan.io/address/0x7f90122bf0700f9e7e1f688fe926940e8839f353)
    function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount) external payable;
    function add_liquidity(uint256[3] memory _amounts, uint256 _min_mint_amount) external payable;
    function add_liquidity(uint256[4] memory _amounts, uint256 _min_mint_amount) external payable;
    function add_liquidity(uint256[5] memory _amounts, uint256 _min_mint_amount) external payable;

    // useUnderlying Curve pool (e.g. https://snowtrace.io/address/0x7f90122bf0700f9e7e1f688fe926940e8839f353)
    function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount, bool _use_underlying) external;
    function add_liquidity(uint256[3] memory _amounts, uint256 _min_mint_amount, bool _use_underlying) external;

    // useMetapool Curve pool (e.g. https://optimistic.etherscan.io/address/0x167e42a1c7ab4be03764a2222aac57f5f6754411)
    function add_liquidity(address _pool, uint256[2] memory _amounts, uint256 _min_mint_amount) external;
    function add_liquidity(address _pool, uint256[3] memory _amounts, uint256 _min_mint_amount) external;
    function add_liquidity(address _pool, uint256[4] memory _amounts, uint256 _min_mint_amount) external;

    function remove_liquidity_one_coin(uint256 token_amount, int128 index, uint256 _min_amount) external;
    function remove_liquidity_one_coin(uint256 token_amount, uint256 index, uint256 _min_amount) external;
}