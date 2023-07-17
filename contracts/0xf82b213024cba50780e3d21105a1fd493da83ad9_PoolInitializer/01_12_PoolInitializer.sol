// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import 'src/interfaces/IPool.sol';
import 'src/interfaces/IStrategy.sol';
import 'src/interfaces/IERC20.sol';

contract PoolInitializer {
    address public admin;

    // Pool has been paused/unpaused
    event InitializePool(uint256 fyTokensPerBase);

    // User is not authorized
    error Unauthorized();

    constructor() {
        admin = msg.sender;
    }

    /// Allows only the authorized contract to execute the method
    modifier authorized(address a) {
        if (msg.sender != a) revert Unauthorized();
        _;
    }

    /// @notice Initializes a YieldSpace Pool and adjusts the current fyToken price
    /// @dev The pool's admin must be the strategy parameter address
    /// @param pool The pool that will get initialized
    /// @param initStrategy The amount of base tokens to provide in Strategy::init
    /// @param baseLP The amount of base tokens to commit as liquidity
    /// @param lendBase The amoutn of base tokens needed to execute the lends
    /// @param ptsToSell The amount of PTs to sell to the pool after initialization
    /// @param minRatio Minimum ratio in the mint call
    /// @param maxRatio Maximum ratio in the mint call
    /// @param lends The lend calls to be made to get fyTokens
    /// @param strategy The strategy that will provide liquidity to the new pool
    function initializePool(
        address pool,
        uint256 initStrategy,
        uint256 baseLP,
        uint256 lendBase,
        uint256 ptsToSell,
        uint256 minRatio,
        uint256 maxRatio,
        bytes[] calldata lends,
        address strategy
    ) public authorized(admin) returns (address) {
        // Get the underlying asset for this market
        IERC20 base = IPool(pool).base();

        // Transfer Base amount to pool
        base.transferFrom(msg.sender, strategy, initStrategy);

        // Initialize the Strategy
        IStrategy(strategy).init(admin);

        // Transfer Base amount to pool
        base.transferFrom(msg.sender, strategy, baseLP + lendBase);

        // Invest in the pool - this method will adjust the rate by selling PTs to the pool
        // This method also returns admin functionality
        IStrategy(strategy).invest(
            IPool(pool),
            baseLP,
            ptsToSell,
            minRatio,
            maxRatio,
            lends
        );

        // Return Strategy tokens from initial investment to the admin
        IERC20(strategy).transfer(
            admin,
            IERC20(strategy).balanceOf(address(this))
        );

        // Return excess base tokens from mint to admin
        base.transfer(admin, base.balanceOf(address(this)));

        // Return admin control of the strategy to the caller
        IStrategy(strategy).setAdmin(msg.sender);

        // The Strategy sets the initializer as the pool's admin, so one more call is necessary
        IPool(pool).setAdmin(msg.sender);

        // emit an event for simulation testing
        uint256 fyTokensPerBase = IPool(pool).sellBasePreview(1000000);
        emit InitializePool(fyTokensPerBase);

        return pool;
    }

    /// Allows the admin to transfer ownership of the contract
    function setAdmin(address a) external authorized(admin) {
        admin = a;
    }
}