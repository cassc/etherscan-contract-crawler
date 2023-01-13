// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface ITokenStorage {
    event SendDividends(uint256 tokensSwapped, uint256 amount);

    function swapTokensForDai(uint256 tokens) external;

    function transferDai(address to, uint256 amount) external;

    function addLiquidity(uint256 tokens, uint256 dais) external;

    function distributeDividends(
        uint256 swapTokensDividends,
        uint256 daiDividends
    ) external;

    function setLiquidityWallet(address _liquidityWallet) external;
}