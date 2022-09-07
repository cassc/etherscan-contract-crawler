// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IPancakeZapV1 {
    /*
     * @notice Zap BNB in a WBNB pool (e.g. WBNB/token)
     * @param _lpToken: LP token address (e.g. CAKE/BNB)
     * @param _tokenAmountOutMin: minimum token amount (e.g. CAKE) to receive in the intermediary swap (e.g. BNB --> CAKE)
     */
    function zapInBNB(address _lpToken, uint256 _tokenAmountOutMin) external payable;
    /*
     * @notice Zap a token in (e.g. token/other token)
     * @param _tokenToZap: token to zap
     * @param _tokenAmountIn: amount of token to swap
     * @param _lpToken: LP token address (e.g. CAKE/BUSD)
     * @param _tokenAmountOutMin: minimum token to receive (e.g. CAKE) in the intermediary swap (e.g. BUSD --> CAKE)
     */
    function zapInToken(
        address _tokenToZap,
        uint256 _tokenAmountIn,
        address _lpToken,
        uint256 _tokenAmountOutMin
    ) external;

    /*
     * @notice Zap two tokens in, rebalance them to 50-50, before adding them to LP
     * @param _token0ToZap: address of token0 to zap
     * @param _token1ToZap: address of token1 to zap
     * @param _token0AmountIn: amount of token0 to zap
     * @param _token1AmountIn: amount of token1 to zap
     * @param _lpToken: LP token address (token0/token1)
     * @param _tokenAmountInMax: maximum token amount to sell (in token to sell in the intermediary swap)
     * @param _tokenAmountOutMin: minimum token to receive in the intermediary swap
     * @param _isToken0Sold: whether token0 is expected to be sold (if false, sell token1)
     */
    function zapInTokenRebalancing(
        address _token0ToZap,
        address _token1ToZap,
        uint256 _token0AmountIn,
        uint256 _token1AmountIn,
        address _lpToken,
        uint256 _tokenAmountInMax,
        uint256 _tokenAmountOutMin,
        bool _isToken0Sold
    ) external;

    /*
     * @notice Zap 1 token and BNB, rebalance them to 50-50, before adding them to LP
     * @param _token1ToZap: address of token1 to zap
     * @param _token1AmountIn: amount of token1 to zap
     * @param _lpToken: LP token address
     * @param _tokenAmountInMax: maximum token amount to sell (in token to sell in the intermediary swap)
     * @param _tokenAmountOutMin: minimum token to receive in the intermediary swap
     * @param _isToken0Sold: whether token0 is expected to be sold (if false, sell token1)
     */
    function zapInBNBRebalancing(
        address _token1ToZap,
        uint256 _token1AmountIn,
        address _lpToken,
        uint256 _tokenAmountInMax,
        uint256 _tokenAmountOutMin,
        bool _isToken0Sold
    ) external payable;

    /*
     * @notice Zap a LP token out to receive BNB
     * @param _lpToken: LP token address (e.g. CAKE/WBNB)
     * @param _lpTokenAmount: amount of LP tokens to zap out
     * @param _tokenAmountOutMin: minimum amount to receive (in BNB/WBNB) in the intermediary swap (e.g. CAKE --> BNB)
     */
    function zapOutBNB(
        address _lpToken,
        uint256 _lpTokenAmount,
        uint256 _tokenAmountOutMin
    ) external;

    /*
     * @notice Zap a LP token out (to receive a token)
     * @param _lpToken: LP token address (e.g. CAKE/BUSD)
     * @param _tokenToReceive: one of the 2 tokens from the LP (e.g. CAKE or BUSD)
     * @param _lpTokenAmount: amount of LP tokens to zap out
     * @param _tokenAmountOutMin: minimum token to receive (e.g. CAKE) in the intermediary swap (e.g. BUSD --> CAKE)
     */
    function zapOutToken(
        address _lpToken,
        address _tokenToReceive,
        uint256 _lpTokenAmount,
        uint256 _tokenAmountOutMin,
        uint256 _totalTokenAmountOutMin
    ) external;

    /*
     * @notice View the details for single zap
     * @dev Use WBNB for _tokenToZap (if BNB is the input)
     * @param _tokenToZap: address of the token to zap
     * @param _tokenAmountIn: amount of token to zap inputed
     * @param _lpToken: address of the LP token
     * @return swapAmountIn: amount that is expected to get swapped in intermediary swap
     * @return swapAmountOut: amount that is expected to get received in intermediary swap
     * @return swapTokenOut: token address of the token that is used in the intermediary swap
     */
    function estimateZapInSwap(
        address _tokenToZap,
        uint256 _tokenAmountIn,
        address _lpToken
    )
        external
        view
        returns (
            uint256 swapAmountIn,
            uint256 swapAmountOut,
            address swapTokenOut
        );
    /*
     * @notice View the details for a rebalancing zap
     * @dev Use WBNB for _token0ToZap (if BNB is the input)
     * @param _token0ToZap: address of the token0 to zap
     * @param _token1ToZap: address of the token0 to zap
     * @param _token0AmountIn: amount for token0 to zap
     * @param _token1AmountIn: amount for token1 to zap
     * @param _lpToken: address of the LP token
     * @return swapAmountIn: amount that is expected to get swapped in intermediary swap
     * @return swapAmountOut: amount that is expected to get received in intermediary swap
     * @return isToken0Sold: whether the token0 is sold (false --> token1 is sold in the intermediary swap)
     */
    function estimateZapInRebalancingSwap(
        address _token0ToZap,
        address _token1ToZap,
        uint256 _token0AmountIn,
        uint256 _token1AmountIn,
        address _lpToken
    )
        external
        view
        returns (
            uint256 swapAmountIn,
            uint256 swapAmountOut,
            bool sellToken0
        );
    /*
     * @notice View the details for single zap
     * @dev Use WBNB for _tokenToReceive (if BNB is the asset to be received)
     * @param _lpToken: address of the LP token to zap out
     * @param _lpTokenAmount: amount of LP token to zap out
     * @param _tokenToReceive: token address to receive
     * @return swapAmountIn: amount that is expected to get swapped for intermediary swap
     * @return swapAmountOut: amount that is expected to get received for intermediary swap
     * @return swapTokenOut: address of the token that is sold in the intermediary swap
     */
    function estimateZapOutSwap(
        address _lpToken,
        uint256 _lpTokenAmount,
        address _tokenToReceive
    )
        external
        view
        returns (
            uint256 swapAmountIn,
            uint256 swapAmountOut,
            address swapTokenOut
        );
    
}