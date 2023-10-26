//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "solady/src/auth/Ownable.sol";

contract MEVGuard is Ownable {
	// This mapping keeps track of the last block a given address performed a transaction and defines a cooldown period.
	mapping(address => uint32) private _mev_cooldowns;

	// This mapping keeps track of addresses that are whitelisted from the cooldown period. (e.g. Exchanges, AMMs like Uniswap, etc.)
	mapping(address => bool) private _mev_excluded;

	// Cooldown period for MEV protection. (e.g. 4 blocks). 
    // Once an address performs a transaction, it cannot perform another transaction for the cooldown period.
    // This is to prevent MEV bots attacks.
	uint MEV_COOLDOWN_BLOCKS = 4;

    // Set status of MEVGuard
    bool MEV_GUARD_ENABLED = false;

    error MEVGuardCooldown();

    function checkCooldown(address sender) internal view {
        // If the sender is whitelisted or if the sender cooldown is zero, skip the check.
        if (_mev_excluded[sender] || _mev_cooldowns[sender] == 0) return;

        // If the sender has already performed a transaction within the cooldown period, revert.
        if (_mev_cooldowns[sender] > block.number) revert MEVGuardCooldown();
    }

    function updateCooldown(address sender) internal {
        // If the sender is whitelisted, skip.
        if (_mev_excluded[sender]) return;

        // Update the sender cooldown.
        _mev_cooldowns[sender] = uint32(block.number + MEV_COOLDOWN_BLOCKS);
    }

    // Excludes an address from the cooldown period (e.g. Exchanges, AMMs like Uniswap, etc.)
    function setMEVExcluded(address sender, bool status) public onlyOwner {
        _mev_excluded[sender] = status;
    }

    // Sets the cooldown period for MEV protection. (e.g. 4 blocks) and enable/disable MEVGuard.
    function setMEVGuard(uint blocks, bool enabled) public onlyOwner {
        MEV_GUARD_ENABLED = enabled;
        if (blocks > 20) revert("MEVGuard: cooldown period too high");
        MEV_COOLDOWN_BLOCKS = blocks;
    }
}