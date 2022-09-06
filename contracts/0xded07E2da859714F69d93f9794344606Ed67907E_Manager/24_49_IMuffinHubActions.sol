// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IMuffinHubActions {
    /// @notice                 Deposit token into recipient's account
    /// @dev                    DO NOT deposit rebasing tokens or multiple-address tokens as it will cause loss of funds.
    ///                         DO NOT withdraw the token you deposit or swap the token out from the contract during the callback.
    /// @param recipient        Recipient's address
    /// @param recipientAccRefId Recipient's account id
    /// @param token            Address of the token to deposit
    /// @param amount           Token amount to deposit
    /// @param data             Arbitrary data that is passed to callback function
    function deposit(
        address recipient,
        uint256 recipientAccRefId,
        address token,
        uint256 amount,
        bytes calldata data
    ) external;

    /// @notice                 Withdraw token from sender's account and send to recipient's address
    /// @param recipient        Recipient's address
    /// @param senderAccRefId   Id of sender's account, i.e. the account to withdraw token from
    /// @param token            Address of the token to withdraw
    /// @param amount           Token amount to withdraw
    function withdraw(
        address recipient,
        uint256 senderAccRefId,
        address token,
        uint256 amount
    ) external;

    /// @notice                 Create pool
    /// @dev                    DO NOT create pool with rebasing tokens or multiple-address tokens as it will cause loss of funds
    /// @param token0           Address of token0 of the pool
    /// @param token1           Address of token1 of the pool
    /// @param sqrtGamma        Sqrt (1 - percentage swap fee of the tier) (precision: 1e5)
    /// @param sqrtPrice        Sqrt price of token0 denominated in token1 (UQ56.72)
    /// @param senderAccRefId   Sender's account id, for paying the base liquidity
    /// @return poolId          Pool id
    function createPool(
        address token0,
        address token1,
        uint24 sqrtGamma,
        uint128 sqrtPrice,
        uint256 senderAccRefId
    ) external returns (bytes32 poolId);

    /// @notice                 Add a new tier to a pool. Called by governanace only.
    /// @param token0           Address of token0 of the pool
    /// @param token1           Address of token1 of the pool
    /// @param sqrtGamma        Sqrt (1 - percentage swap fee) (precision: 1e5)
    /// @param senderAccRefId   Sender's account id, for paying the base liquidity
    /// @return tierId          Id of the new tier
    function addTier(
        address token0,
        address token1,
        uint24 sqrtGamma,
        uint256 senderAccRefId
    ) external returns (uint8 tierId);

    /// @notice                 Swap one token for another
    /// @param tokenIn          Input token address
    /// @param tokenOut         Output token address
    /// @param tierChoices      Bitmap to select which tiers are allowed to swap
    /// @param amountDesired    Desired swap amount (positive: input, negative: output)
    /// @param recipient        Recipient's address
    /// @param recipientAccRefId Recipient's account id
    /// @param senderAccRefId   Sender's account id
    /// @param data             Arbitrary data that is passed to callback function
    /// @return amountIn        Input token amount
    /// @return amountOut       Output token amount
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 tierChoices,
        int256 amountDesired,
        address recipient,
        uint256 recipientAccRefId,
        uint256 senderAccRefId,
        bytes calldata data
    ) external returns (uint256 amountIn, uint256 amountOut);

    /// @notice                 Parameters for the multi-hop swap function
    /// @param path             Multi-hop path. encodePacked(address tokenA, uint16 tierChoices, address tokenB, uint16 tierChoices ...)
    /// @param amountDesired    Desired swap amount (positive: input, negative: output)
    /// @param recipient        Recipient's address
    /// @param recipientAccRefId Recipient's account id
    /// @param senderAccRefId   Sender's account id
    /// @param data             Arbitrary data that is passed to callback function
    struct SwapMultiHopParams {
        bytes path;
        int256 amountDesired;
        address recipient;
        uint256 recipientAccRefId;
        uint256 senderAccRefId;
        bytes data;
    }

    /// @notice                 Swap one token for another along the specified path
    /// @param params           SwapMultiHopParams struct
    /// @return amountIn        Input token amount
    /// @return amountOut       Output token amount
    function swapMultiHop(SwapMultiHopParams calldata params) external returns (uint256 amountIn, uint256 amountOut);
}