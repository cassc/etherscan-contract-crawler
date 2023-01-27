// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.16;

// See https://etherscan.io/address/0xa79828df1850e8a3a3064576f380d90aecdd3359#code for an example
/*  solhint-disable func-name-mixedcase, var-name-mixedcase */
interface I3CrvMetaPoolZap {
    function add_liquidity(address pool, uint256[4] memory depositAmounts, uint256 minMintAmount)
        external
        returns (uint256);

    function remove_liquidity_one_coin(address pool, uint256 burnAmount, int128 index, uint256 minAmount)
        external
        returns (uint256);

    function remove_liquidity_imbalance(address _pool, uint256[4] memory _amounts, uint256 _maxBurnAmount)
        external
        returns (uint256);

    function calc_withdraw_one_coin(address pool, uint256 tokenAmount, int128 index) external view returns (uint256);
}
/*  solhint-disable func-name-mixedcase, var-name-mixedcase */