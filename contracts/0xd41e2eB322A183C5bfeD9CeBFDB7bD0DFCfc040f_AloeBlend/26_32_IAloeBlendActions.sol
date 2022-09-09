// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IAloeBlendActions {
    /**
     * @notice Deposits tokens in proportion to the vault's current holdings
     * @dev These tokens sit in the vault and are not used as liquidity
     * until the next rebalance. Also note it's not necessary to check
     * if user manipulated price to deposit cheaper, as the value of range
     * orders can only by manipulated higher.
     * @param amount0Max Max amount of TOKEN0 to deposit
     * @param amount1Max Max amount of TOKEN1 to deposit
     * @param amount0Min Ensure `amount0` is greater than this
     * @param amount1Min Ensure `amount1` is greater than this
     * @return shares Number of shares minted
     * @return amount0 Amount of TOKEN0 deposited
     * @return amount1 Amount of TOKEN1 deposited
     */
    function deposit(
        uint256 amount0Max,
        uint256 amount1Max,
        uint256 amount0Min,
        uint256 amount1Min
    )
        external
        returns (
            uint256 shares,
            uint256 amount0,
            uint256 amount1
        );

    /**
     * @notice Withdraws tokens in proportion to the vault's current holdings
     * @param shares Shares burned by sender
     * @param amount0Min Revert if resulting `amount0` is smaller than this
     * @param amount1Min Revert if resulting `amount1` is smaller than this
     * @return amount0 Amount of token0 sent to recipient
     * @return amount1 Amount of token1 sent to recipient
     */
    function withdraw(
        uint256 shares,
        uint256 amount0Min,
        uint256 amount1Min
    ) external returns (uint256 amount0, uint256 amount1);

    /**
     * @notice Rebalances vault to maintain 50/50 inventory ratio
     * @dev `rewardToken` may be something other than token0 or token1, in which case the available maintenance budget
     * is equal to the contract's balance. Also note that this will revert unless both silos report that removal of
     * `rewardToken` is allowed. For example, a Compound silo would block removal of its cTokens.
     * @param rewardToken The ERC20 token in which the reward should be denominated. If `rewardToken` is the 0 address,
     * no reward will be given. Otherwise, the reward is based on (a) time elapsed since primary position last moved
     * and (b) the contract's estimate of how much each unit of gas costs. Since (b) is fully determined by past
     * contract interactions and is known to all participants, (a) creates a Dutch Auction for calling this function.
     */
    function rebalance(address rewardToken) external;
}