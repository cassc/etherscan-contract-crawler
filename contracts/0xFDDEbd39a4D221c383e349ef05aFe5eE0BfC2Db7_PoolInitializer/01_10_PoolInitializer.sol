// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import 'src/Interfaces/IPool.sol';
import 'src/Interfaces/IERC20.sol';

contract PoolInitializer {
    address admin;

    // Pool has been paused/unpaused
    event InitializePool(uint256 basePerFyToken);

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

    // @notice Initializes a Euler based shares token YieldSpace Pool and adjusts the current fyToken price
    // @param pool The pool that will get initialized
    // @param base The underlying token address traded against fyTokens
    // @param fyToken The principal token address being traded against
    // @param baseLP The amount of base tokens to commit as liquidity
    // @param fyTokenSold The amount of fyTokens to sell to the pool in order to adjust the fyToken price
    function initializePool(
        address pool,
        address base,
        address fyToken,
        uint256 baseLP,
        uint256 fyTokenSold
    ) public authorized(admin) returns (address) {
        // Transfer Base amount to pool
        IERC20(base).transferFrom(msg.sender, address(pool), baseLP);
        // Initialize the pool's liquidity, granting LP tokens and creating "virtual" fyToken liquidity
        IPool(pool).init(msg.sender);
        // Transfer fyTokens to sell to the pool
        IERC20(fyToken).transferFrom(msg.sender, address(pool), fyTokenSold);
        // Sell fyTokens to the pool, adjusting the fyToken price
        uint256 baseOut = IPool(pool).sellFYToken(msg.sender, 0);
        // Retake admin control
        setPoolAdmin(pool, msg.sender);
        // emit an event for simulation testing
        emit InitializePool(baseOut);

        return pool;
    }

    /// Allows the admin to transfer ownership of the contract
    function setAdmin(address a) external authorized(admin) {
        admin = a;
    }

    // Allows the pool contract to reset the admin to another address
    function setPoolAdmin(address p, address a) internal {
        IPool(p).setAdmin(a);
    }
}