// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import '../Adminable.sol';
import './GeneralIDO.sol';
import './WithLimits.sol';

// TODO: two types of whitelists, two limits
abstract contract WithWhitelist is Adminable, GeneralIDO, WithLimits {
    bool public whitelistEnabled = true;
    mapping(address => bool) public whitelisted;
    // Special allocations per address
    mapping(address => uint256) public whitelistUserAllocation;
    address[] public whitelistedAddresses;
    uint256 internal whitelistedCount;
    // Sum of all active special WL allocs
    uint256 internal specialWlAlloc;

    function getWhitelistedAddresses() public view returns (address[] memory) {
        return whitelistedAddresses;
    }

    // Return tokens amount allocated for whitelist
    function whitelistAllocation() public view returns (uint256) {
        uint256 whitelistAlloc = calculatePurchaseAmount(maxSell);
        return whitelistAlloc * whitelistedCount + calculatePurchaseAmount(specialWlAlloc);
    }

    function toggleWhitelist(bool status) public onlyOwnerOrAdmin {
        whitelistEnabled = status;
    }

    function whitelistAccount(address account) internal {
        if (!whitelisted[account]) {
            whitelisted[account] = true;
            whitelistedAddresses.push(account);
            whitelistedCount += 1;
        }
    }

    function batchSetWhitelistUserAllocation(uint256 amount, address[] calldata addresses) public onlyOwnerOrAdmin {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelistAccount(addresses[i]);
            whitelistUserAllocation[addresses[i]] = amount;
            specialWlAlloc += amount;
        }
    }

    function batchAddWhitelisted(address[] calldata addresses) external onlyOwnerOrAdmin {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelistAccount(addresses[i]);
        }
    }

    function batchRemoveWhitelisted(address[] calldata addresses) external onlyOwnerOrAdmin {
        for (uint256 i = 0; i < addresses.length; i++) {
            if (whitelisted[addresses[i]]) {
                whitelisted[addresses[i]] = false;
                whitelistedCount -= 1;
                specialWlAlloc -= whitelistUserAllocation[addresses[i]];
            }
        }
    }
}