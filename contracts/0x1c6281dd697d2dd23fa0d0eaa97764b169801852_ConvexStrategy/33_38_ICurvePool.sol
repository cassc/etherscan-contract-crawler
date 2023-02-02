// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.16;

// See https://curve.readthedocs.io/exchange-deposits.html#curve-stableswap-exchange-deposit-contracts
/*  solhint-disable func-name-mixedcase, var-name-mixedcase */
interface ICurvePool {
    function lp_token() external view returns (address);

    function add_liquidity(uint256[2] memory depositAmounts, uint256 minMintAmount) external returns (uint256);

    function remove_liquidity_one_coin(uint256 _burn_amount, int128 i, uint256 _min_amount)
        external
        returns (uint256);

    function remove_liquidity_imbalance(uint256[2] memory _amounts, uint256 _max_burn_amount)
        external
        returns (uint256);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);
    function get_virtual_price() external view returns (uint256);
}
/*  solhint-disable func-name-mixedcase, var-name-mixedcase */