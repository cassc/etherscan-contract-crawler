// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

interface IDepositor {
    // solhint-disable
    function add_liquidity(
        address _pool,
        uint256[4] calldata _deposit_amounts,
        uint256 _min_mint_amount
    ) external returns (uint256);

    // solhint-enable

    // solhint-disable
    function remove_liquidity_one_coin(
        address _pool,
        uint256 _burn_amount,
        int128 i,
        uint256 _min_amounts
    ) external returns (uint256);
    // solhint-enable
}