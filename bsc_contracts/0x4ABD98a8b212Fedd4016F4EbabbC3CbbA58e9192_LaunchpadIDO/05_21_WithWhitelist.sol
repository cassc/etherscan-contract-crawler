// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import '../Adminable.sol';
import './GeneralIDO.sol';
import './WithLimits.sol';

// TODO: two types of whitelists, two limits
abstract contract WithWhitelist is Adminable, GeneralIDO, WithLimits {
    bool public whitelistEnabled = true;
    mapping(address => bool) public whitelisted;
    address[] public whitelistedAddresses;
    uint256 internal whitelistedCount;

    function getWhitelistedAddresses() public view returns (address[] memory) {
        return whitelistedAddresses;
    }

    // Return tokens amount allocated for whitelist
    function whitelistAllocation() public view returns (uint256) {
        uint256 whitelistAlloc = calculatePurchaseAmount(maxSell);
        return whitelistAlloc * whitelistedCount;
    }

    function toggleWhitelist(bool status) public onlyOwnerOrAdmin {
        whitelistEnabled = status;
    }

    function batchAddWhitelisted(address[] calldata addresses) external onlyOwnerOrAdmin {
        for (uint256 i = 0; i < addresses.length; i++) {
            if (!whitelisted[addresses[i]]) {
                whitelisted[addresses[i]] = true;
                whitelistedAddresses.push(addresses[i]);
                whitelistedCount += 1;
            }
        }
    }

    function batchRemoveWhitelisted(address[] calldata addresses) external onlyOwnerOrAdmin {
        for (uint256 i = 0; i < addresses.length; i++) {
            if (whitelisted[addresses[i]]) {
                whitelisted[addresses[i]] = false;
                whitelistedCount -= 1;
            }
        }
    }
}