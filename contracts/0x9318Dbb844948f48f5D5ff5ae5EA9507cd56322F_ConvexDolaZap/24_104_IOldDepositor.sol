// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

interface IOldDepositor {
    // solhint-disable
    function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount)
        external
        returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount
    ) external returns (uint256);

    function coins(uint256 i) external view returns (address);

    function base_coins(uint256 i) external view returns (address);
    // solhint-enable
}