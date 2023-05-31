// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

interface VanillaV1API01 {
    /**
        @notice Checks if the given ERC-20 token will be eligible for rewards (i.e. a safelisted token)
        @param token The ERC-20 token address
     */
    function isTokenRewarded(address token) external view returns (bool);

    /// internally tracked reserves for price manipulation protection for each token (Uniswap uses uint112 so uint128 is plenty)
    function wethReserves(address token) external view returns (uint128);


    function epoch() external view returns (uint256);

    function vnlContract() external view returns (address);

    function reserveLimit() external view returns (uint128);

    /// Price data, indexed as [owner][token]
    function tokenPriceData(address owner, address token) external view returns (uint256 ethSum,
        uint256 tokenSum,
        uint256 weightedBlockSum,
        uint256 latestBlock);

    /**
        @notice Estimates the reward.
        @dev Estimates the reward for given `owner` when selling `numTokensSold``token`s for `numEth` Ether. Also returns the individual components of the reward formula.
        @return profitablePrice The expected amount of Ether for this trade. Profit of this trade can be calculated with `numEth`-`profitablePrice`.
        @return avgBlock The volume-weighted average block for the `owner` and `token`
        @return htrs The Holding/Trading Ratio, Squared- estimate for this trade, percentage value range in fixed point range 0-100.0000.
        @return vpc The Value-Protection Coefficient- estimate for this trade, percentage value range in fixed point range 0-100.0000.
        @return reward The token reward estimate for this trade.
     */
    function estimateReward(
        address owner,
        address token,
        uint256 numEth,
        uint256 numTokensSold
    ) external view returns (
        uint256 profitablePrice,
        uint256 avgBlock,
        uint256 htrs,
        uint256 vpc,
        uint256 reward
    );

    /**
        @notice Buys the tokens with Ether. Use the external pricefeed for pricing.
        @dev Buys the `numToken` tokens for all the msg.value Ether, before `blockTimeDeadline`

        @param token The address of ERC20 token to be bought
        @param numToken The amount of ERC20 tokens to be bought
        @param blockTimeDeadline The block timestamp when this buy-transaction expires
     */
    function depositAndBuy(
        address token,
        uint256 numToken,
        uint256 blockTimeDeadline
    ) external payable;

    /**
        @notice Buys the tokens with WETH. Use the external pricefeed for pricing.
        @dev Buys the `numToken` tokens for all the msg.value Ether, before `blockTimeDeadline`

        @param token The address of ERC20 token to be bought
        @param numEth The amount of WETH to spend. Needs to be pre-approved for the VanillaRouter.
        @param numToken The amount of ERC20 tokens to be bought
        @param blockTimeDeadline The block timestamp when this buy-transaction expires
     */
    function buy(
        address token,
        uint256 numEth,
        uint256 numToken,
        uint256 blockTimeDeadline
    ) external;

    /**
        @notice Sells the tokens the caller owns. Use the external pricefeed for pricing.
        @dev Sells the `numToken` tokens msg.sender owns, for `numEth` ether, before `blockTimeDeadline`

        @param token The address of ERC20 token to be sold
        @param numToken The amount of ERC20 tokens to be sold
        @param numEthLimit The minimum amount of ether to be received for exchange (the limit order)
        @param blockTimeDeadline The block timestamp when this sell-transaction expires
     */
    function sell(
        address token,
        uint256 numToken,
        uint256 numEthLimit,
        uint256 blockTimeDeadline
    ) external;

    /**
        @notice Sells the tokens the caller owns. Use the external pricefeed for pricing.
        @dev Sells the `numToken` tokens msg.sender owns, for `numEth` ether, before `blockTimeDeadline`

        @param token The address of ERC20 token to be sold
        @param numToken The amount of ERC20 tokens to be sold
        @param numEthLimit The minimum amount of ether to be received for exchange (the limit order)
        @param blockTimeDeadline The block timestamp when this sell-transaction expires
     */
    function sellAndWithdraw(
        address token,
        uint256 numToken,
        uint256 numEthLimit,
        uint256 blockTimeDeadline
    ) external;
}