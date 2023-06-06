// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./VPool.sol";

/// @title Vesper pools have deposited funds into many protocols including the Euler protocol.
/// Euler protocol got hacked and that has impacted some strategies in Vesper.
/// To fix the strategies, specific measures must be taken, such as removing the strategy's pool token and migrating strategy accounting without fund.
/// This pool hot fix will enable transfer of pool tokens from strategy and migrating strategy to new strategy notice it will not move fund.
contract VPool_HotFix is VPool {
    constructor(string memory name_, string memory symbol_, address token_) VPool(name_, symbol_, token_) {}

    function transferTokens(address from_, address to_) external onlyGovernor {
        uint256 _fromBalance = balanceOf(from_);
        require(_fromBalance > 0, "zero-balance");
        _transfer(from_, to_, _fromBalance);
        require(balanceOf(from_) == 0, "non-zero-balance");
    }

    function migrateStrategyForcefully(address old_, address new_) external onlyGovernor {
        require(
            IStrategy(new_).pool() == address(this) && IStrategy(old_).pool() == address(this),
            Errors.INVALID_STRATEGY
        );
        IPoolAccountant(poolAccountant).migrateStrategy(old_, new_);
    }
}