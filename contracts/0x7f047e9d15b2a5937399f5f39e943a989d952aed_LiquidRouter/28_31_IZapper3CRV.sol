// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

interface IZapper3CRV {
    function add_liquidity(
        address _pool,
        uint256[4] memory _deposit_amounts,
        uint256 _min_mint_amount,
        address _recipient
    ) external;

    function remove_liquidity(address _pool, uint256 _burn_amount, uint256[4] calldata _min_amounts, address _receiver)
        external;

    function remove_liquidity_one_coin(
        address _pool,
        uint256 _burn_amount,
        int128 index,
        uint256 _min_amounts,
        address _receiver
    ) external;

    function calc_token_amount(address _ppol, uint256[4] memory _amounts, bool _is_deposit)
        external
        view
        returns (uint256);
}