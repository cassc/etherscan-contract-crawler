// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.11;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICurveMetaPool is IERC20{
    function coins(uint256 index) external view returns(address);

    function add_liquidity(uint256[2] calldata _amounts, uint256 _min_mint_amount) external;
    function remove_liquidity(uint256 _burning_amount, uint256[2] calldata _min_amounts) external;
    function remove_liquidity_imbalance(uint256[2] calldata _amounts, uint256 _maxBurningAmount) external;
}

interface ICurvePool {
    function add_liquidity(uint256[3] calldata _amounts, uint256 _min_mint_amount) external;
    function remove_liquidity(uint256 _burning_amount, uint256[3] calldata _min_amounts) external;
    function remove_liquidity_imbalance(uint256[3] calldata _amounts, uint256 _maxBurningAmount) external;
    function remove_liquidity_one_coin(uint256 _3crv_token_amount, int128 i, uint256 _min_amount) external;
    function calc_token_amount(uint256[3] calldata _amounts, bool _deposit) external view returns(uint256);
    function calc_withdraw_one_coin(uint256 _token_amount, int128 _i) external view returns(uint256);
}

interface ICurveZap {
    function remove_liquidity(
        address _pool,
        uint256 _burn_amount,
        uint256[4] calldata _min_amounts,
        address _receiver
    ) external returns(uint256[4] memory);
}