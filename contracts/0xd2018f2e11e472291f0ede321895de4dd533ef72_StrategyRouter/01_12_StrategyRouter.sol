// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {IStrategy} from 'src/interfaces/IStrategy.sol';
import {IPool} from 'src/interfaces/IPool.sol';
import {IERC20} from 'src/interfaces/IERC20.sol';

/// @dev The StrategyRouter contract allows users to interact with YieldSpace
/// pools and their respective strategies through a single transaction. By
/// approving the router, a user could send a base asset to a pool and receive
/// Strategy shares in return. Conversely, a user could also use the router to
/// move from Strategy shares to fyTokens and base assets from the YieldSpace
/// pool as well.
contract StrategyRouter {
    /// @dev Emitted when a user mints Strategy tokens
    event Mint(
        address indexed strategy,
        address indexed pool,
        uint256 baseIn,
        uint256 fyTokenIn,
        uint256 strategyMinted,
        address to
    );

    /// @dev Emitted when a user burns Strategy tokens for iPTs and underlying
    event Burn(
        address indexed strategy,
        address indexed pool,
        uint256 baseOut,
        uint256 fyTokenOut,
        uint256 strategyBurned,
        address to
    );

    /// @notice Mints shares to the user in exchange for base
    /// @param strategy_ The strategy being used to mint
    /// @param assets_ Number of base tokens to use to mint shares
    /// @param pts_ Number of PTs to use to mint shares
    /// @param minRatio_ Minimum ratio used in pool's mint call
    /// @param maxRatio_ Maximum ratio used in pool's mint call
    /// @return minted_ Amount of shares received
    function mint(
        address strategy_,
        uint256 assets_,
        uint256 pts_,
        uint256 minRatio_,
        uint256 maxRatio_
    ) external returns (uint256 minted_) {
        // Acquire LP tokens from the pool
        IPool pool = IStrategy(strategy_).pool();
        IERC20(pool.base()).transferFrom(msg.sender, address(pool), assets_);
        IERC20(pool.fyToken()).transferFrom(msg.sender, address(pool), pts_);
        pool.mint(strategy_, msg.sender, minRatio_, maxRatio_);

        // Mint shares from the strategy
        minted_ = IStrategy(strategy_).mint(msg.sender);

        emit Mint(strategy_, address(pool), assets_, pts_, minted_, msg.sender);
    }

    function mintWithUnderlying(
        address strategy_,
        uint256 assets_,
        uint256 ptsToBuy_,
        uint256 minRatio_,
        uint256 maxRatio_
    ) external returns (uint256 minted_) {
        // Acquire LP tokens from the pool
        IPool pool = IStrategy(strategy_).pool();
        IERC20(pool.base()).transferFrom(msg.sender, address(pool), assets_);

        pool.mintWithBase(
            strategy_,
            msg.sender,
            ptsToBuy_,
            minRatio_,
            maxRatio_
        );

        // Mint shares from the strategy
        minted_ = IStrategy(strategy_).mint(msg.sender);

        emit Mint(strategy_, address(pool), assets_, 0, minted_, msg.sender);
    }

    /// @notice Burns shares from the user and returns base
    /// @param strategy_ The strategy being used to burn
    /// @param shares_ Amount of Strategy shares to burn
    /// @param minRatio_ Minimum ratio used in pool's mint call
    /// @param maxRatio_ Maximum ratio used in pool's mint call
    /// @return baseReceived_ Amount of base tokens returned to the user
    /// @return iptReceived_ Amount of iPTs returned to the user
    function burn(
        address strategy_,
        uint256 shares_,
        uint256 minRatio_,
        uint256 maxRatio_
    ) external returns (uint256 baseReceived_, uint256 iptReceived_) {
        // Get the active pool for the strategy
        address pool = address(IStrategy(strategy_).pool());

        // Burn the shares for LP tokens
        IERC20(strategy_).transferFrom(msg.sender, strategy_, shares_);
        IStrategy(strategy_).burn(pool);

        // Burn the LP tokens
        (, baseReceived_, iptReceived_) = IStrategy(strategy_).pool().burn(
            msg.sender,
            msg.sender,
            minRatio_,
            maxRatio_
        );

        emit Burn(
            strategy_,
            pool,
            baseReceived_,
            iptReceived_,
            shares_,
            msg.sender
        );
    }

    /// @notice Burns shares from the user and returns base and iPTs
    /// @param strategy_ The strategy being used to burn
    /// @param shares_ Amount of Strategy shares to burn
    /// @param minRatio_ Minimum ratio used in pool's mint call
    /// @param maxRatio_ Maximum ratio used in pool's mint call
    /// @return baseReceived_ Amount of base tokens returned to the user
    function burnForUnderlying(
        address strategy_,
        uint256 shares_,
        uint256 minRatio_,
        uint256 maxRatio_
    ) external returns (uint256 baseReceived_) {
        // Get the active pool for the strategy
        address pool = address(IStrategy(strategy_).pool());

        // Burn the shares for LP tokens
        IERC20(strategy_).transferFrom(msg.sender, strategy_, shares_);
        IStrategy(strategy_).burn(pool);

        // Burn the LP tokens
        (, baseReceived_) = IStrategy(strategy_).pool().burnForBase(
            msg.sender,
            minRatio_,
            maxRatio_
        );

        emit Burn(strategy_, pool, baseReceived_, 0, shares_, msg.sender);
    }

    /// @notice Mints shares when strategy is divested
    /// @param strategy_ The strategy being used to mint
    /// @param assets_ Amount of base asset to mint with
    /// @return minted_ Amount of shares minted to caller
    function mintDivested(
        address strategy_,
        uint256 assets_
    ) external returns (uint256 minted_) {
        IStrategy(strategy_).base().transferFrom(
            msg.sender,
            strategy_,
            assets_
        );
        minted_ = IStrategy(strategy_).mintDivested(msg.sender);

        emit Mint(strategy_, address(0), assets_, 0, minted_, msg.sender);
    }

    /// @notice Burns shares for base asset when strategy is divested
    /// @param strategy_ The strategy being used to burn
    /// @param shares_ Amount of shares to burn
    /// @param received_ Amount of base tokens received
    function burnDivested(
        address strategy_,
        uint256 shares_
    ) external returns (uint256 received_) {
        IERC20(strategy_).transferFrom(msg.sender, strategy_, shares_);
        received_ = IStrategy(strategy_).burnDivested(msg.sender);

        emit Burn(strategy_, address(0), received_, 0, shares_, msg.sender);
    }
}