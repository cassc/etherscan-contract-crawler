// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./IVanillaV1Token02.sol";
import "./IVanillaV1Safelist01.sol";

/// @title Entry point API for Vanilla trading router
interface IVanillaV1Router02 {

    /// @notice Gets the epoch block.number used in reward calculations
    function epoch() external view returns (uint256);

    /// @notice Gets the address of the VNL token contract
    function vnlContract() external view returns (IVanillaV1Token02);

    /// @dev data for calculating volume-weighted average prices, average purchasing block, and limiting trades per block
    struct PriceData {
        uint256 weightedBlockSum;
        uint112 ethSum;
        uint112 tokenSum;
        uint32 latestBlock;
    }

    /// @notice Price data, indexed as [owner][token]
    function tokenPriceData(address owner, address token) external view returns (
        uint256 weightedBlockSum,
        uint112 ethSum,
        uint112 tokenSum,
        uint32 latestBlock);

    /// @dev Emitted when tokens are sold.
    /// @param seller The owner of tokens.
    /// @param token The address of the sold token.
    /// @param amount Number of sold tokens.
    /// @param eth The received ether from the trade.
    /// @param profit The calculated profit from the trade.
    /// @param reward The amount of VanillaGovernanceToken reward tokens transferred to seller.
    event TokensSold(
        address indexed seller,
        address indexed token,
        uint256 amount,
        uint256 eth,
        uint256 profit,
        uint256 reward
    );

    /// @dev Emitted when tokens are bought.
    /// @param buyer The new owner of tokens.
    /// @param token The address of the purchased token.
    /// @param eth The amount of ether spent in the trade.
    /// @param amount Number of purchased tokens.
    event TokensPurchased(
        address indexed buyer,
        address indexed token,
        uint256 eth,
        uint256 amount
    );

    /// @notice Gets the address of the safelist contract
    function safeList() external view returns (IVanillaV1Safelist01);


    struct TradeResult {
        /// the number of Ether received in the trade
        uint256 price;
        /// the length of observable history available in Uniswap v3 pool (5 minute cap)
        uint256 twapPeriodInSeconds;
        /// the number of Ether expected to make trade profitable
        uint256 profitablePrice;
        /// the max number of Ether to be used in reward calculations (also equals the 5-min capped TWAP price from the pool)
        uint256 maxProfitablePrice;
        /// the amount of rewardable profit to be used in reward calculations (the full profit equals `profitablePrice - price`)
        uint256 rewardableProfit;
        /// the amount of VNL reward for this trade
        uint256 reward;
    }

    struct RewardEstimate {
        /// estimate when trading a token in a low-fee Uniswap v3 pool (0.05%)
        TradeResult low;
        /// estimate when trading a token in a medium-fee Uniswap v3 pool (0.3%)
        TradeResult medium;
        /// estimate when trading a token in a high-fee Uniswap v3 pool (1.0%)
        TradeResult high;
    }

    /// @notice Estimates the reward. Not intended to be called from other contracts.
    /// @dev Estimates the reward for given `owner` when selling `numTokensSold``token`s for `numEth` Ether. Also returns the individual components of the reward formula.
    /// @return avgBlock The volume-weighted average block for the `owner` and `token`
    /// @return htrs The Holding/Trading Ratio, Squared- estimate for this trade, percentage value range in fixed point range 0-100.0000.
    /// @return estimate The token reward estimate for this trade for every Uniswap v3 fee-tier.
    function estimateReward(
        address owner,
        address token,
        uint256 numEth,
        uint256 numTokensSold
    ) external view returns (
        uint256 avgBlock,
        uint256 htrs,
        RewardEstimate memory estimate
    );

    /// @notice Delegate call to multiple functions in this Router and return their results iff they all succeed
    /// @param data The function calls encoded
    /// @return results The results of the encoded function calls, in the same order
    function execute(bytes[] calldata data) external returns (bytes[] memory results);

    /// @notice Delegate call to multiple functions in this Router and return their results iff they all succeed
    /// @dev All `msg.value` will be wrapped to WETH before executing the functions.
    /// @param data The function calls encoded
    /// @return results The results of the encoded function calls, in the same order
    function executePayable(bytes[] calldata data) external payable returns (bytes[] memory results);

    struct OrderData {
        // The address of the token to be bought or sold
        address token;

        // if true, buy-order transfers WETH from caller and sell-order transfers WETHs back to caller without withdrawing
        // if false, it's assumed that executePayable is used to deposit/withdraw WETHs before order
        bool useWETH;

        // The exact amount of WETH to be spent when buying or the limit amount of WETH to be received when selling.
        uint256 numEth;

        // The exact amount of token to be sold when selling or the limit amount of token to be received when buying.
        uint256 numToken;

        // The block.timestamp when this order expires
        uint256 blockTimeDeadline;

        // The Uniswap v3 fee tier to use for the swap (500 = 0.05%, 3000 = 0.3%, 10000 = 1.0%)
        uint24 fee;
    }

    /// @notice Buys the tokens with WETH. Use the external pricefeed for pricing. Do not send ether to this function.
    /// @dev Buys the `buyOrder.numToken` tokens for all the `buyOrder.numEth` WETH, before `buyOrder.blockTimeDeadline`
    /// @param buyOrder.token The address of ERC20 token to be bought
    /// @param buyOrder.useWETH Whether to buy directly with caller's WETHs instead of depositing `msg.value`
    /// @param buyOrder.numEth The amount of WETH to spend.
    /// @param buyOrder.numToken The minimum amount of ERC20 tokens to be bought (the limit order)
    /// @param buyOrder.blockTimeDeadline The block timestamp when this buy-transaction expires
    function buy( OrderData calldata buyOrder ) payable external;

    /// @notice Sells the tokens the caller owns for WETH. Use the external pricefeed for pricing. Do not send ether to this function.
    /// @dev Sells the `sellOrder.numToken` tokens msg.sender owns, for `sellOrder.numEth` ether, before `sellOrder.blockTimeDeadline`
    /// @param sellOrder.token The address of ERC20 token to be sold
    /// @param sellOrder.useWETH Whether to transfer WETHs directly to caller instead of withdrawing them to Ether
    /// @param sellOrder.numToken The amount of ERC20 tokens to be sold
    /// @param sellOrder.numEth The minimum amount of ether to be received for exchange (the limit order)
    /// @param sellOrder.blockTimeDeadline The block timestamp when this sell-transaction expires
    function sell( OrderData calldata sellOrder ) payable external;

    /// @notice Transfer all the tokens msg.sender owns to msg.sender
    /// @param token The address of ERC20 token to be withdrawn
    function withdrawTokens(address token) external;

    /// @notice Migration the token position the msg.sender holds to the next version.
    /// @param token The address of ERC20 token position to be migrated
    /// @param nextVersion The address of the next Vanilla Router version.
    function migratePosition(address token, address nextVersion) external;
}