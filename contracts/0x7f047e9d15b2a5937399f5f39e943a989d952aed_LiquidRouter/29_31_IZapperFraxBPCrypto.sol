// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

interface IZapperFraxBPCrypto {
    function add_liquidity(
        address _pool,
        uint256[3] memory _deposit_amounts,
        uint256 _min_mint_amount,
        bool _use_eth,
        address _receiver
    ) external payable;

    function remove_liquidity(
        address _pool,
        uint256 _burn_amount,
        uint256[3] calldata _min_amounts,
        bool _use_eth,
        address _receiver
    ) external;

    function remove_liquidity_one_coin(
        address _pool,
        uint256 _burn_amount,
        uint256 i,
        uint256 _min_amount,
        bool _use_eth,
        address _receiver
    ) external;

    function calc_token_amount(address _pool, uint256[3] memory _amounts) external view returns (uint256);

    function calc_withdraw_one_coin(address _pool, uint256 _token_amount, uint256 i) external view returns (uint256);
}