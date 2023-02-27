// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import '../Adminable.sol';

abstract contract WithWhitelist is Adminable {
    bool public whitelistEnabled = true;

    // A general mapping for the status, holds both normal and special WL addresses
    mapping(address => bool) public whitelisted;
    // This mapping allows is to differentiate between normal and special addresses
    mapping(address => bool) public whitelistedSpecial;
    address[] public wlAddresses;
    address[] public wlSpecialAddresses;
    uint256 internal wlCount;
    uint256 internal wlSpecialCount;

    // Suits as the simple max allocation during the public round of sale
    uint256 public wlAllocation;
    uint256 public wlSpecialAllocation;

    event WhitelistAllocationChanged(uint256 allocation, bool special);
    event WhitelistEnabled(bool status);

    function getWhitelistedAddresses() public view returns (address[] memory) {
        return wlAddresses;
    }

    // Return currency value allocated for whitelist + special whitelist
    function whitelistAllocation() public view returns (uint256) {
        return (wlAllocation * wlCount) + (wlSpecialAllocation * wlSpecialCount);
    }

    function setWlAllocation(uint256 value, bool special) public onlyOwnerOrAdmin {
        if (special) {
            wlSpecialAllocation = value;
        } else {
            wlAllocation = value;
        }
        emit WhitelistAllocationChanged(value, special);
    }

    function getUserWlAllocation(address account) public view returns (uint256) {
        if (!whitelisted[account]) return 0;

        return whitelistedSpecial[account] ? wlSpecialAllocation : wlAllocation;
    }

    function toggleWhitelist(bool status) public onlyOwnerOrAdmin {
        whitelistEnabled = status;
        emit WhitelistEnabled(status);
    }

    function batchAddWhitelisted(bool special, address[] calldata addresses) external onlyOwnerOrAdmin {
        for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            if (whitelisted[addr]) {
                continue;
            }

            whitelisted[addr] = true;

            if (special) {
                whitelistedSpecial[addr] = true;
                wlSpecialAddresses.push(addr);
                wlSpecialCount += 1;
            } else {
                wlAddresses.push(addr);
                wlCount += 1;
            }
        }
    }

    function batchRemoveWhitelisted(address[] calldata addresses) external onlyOwnerOrAdmin {
        uint256[] memory indexes = getArrayItemIndexes(wlAddresses, addresses);
        uint256[] memory specialIndexes = getArrayItemIndexes(wlSpecialAddresses, addresses);

        for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            if (!whitelisted[addr]) {
                continue;
            }
            bool special = whitelistedSpecial[addr];

            whitelisted[addr] = false;
            whitelistedSpecial[addr] = false;
            if (special) {
                wlSpecialCount -= 1;
                delete wlSpecialAddresses[specialIndexes[i]];
            } else {
                wlCount -= 1;
                delete wlSpecialAddresses[indexes[i]];
            }
        }
    }

    // Return indexes of search items in the source array. We assume that all search values exist in source
    function getArrayItemIndexes(address[] storage source, address[] calldata search)
        internal
        view
        returns (uint256[] memory)
    {
        uint256[] memory indexes = new uint256[](search.length);

        for (uint256 j = 0; j < search.length; j++) {
            address b = search[j];

            for (uint256 i = 0; i < source.length; i++) {
                address a = source[i];

                if (a == b) {
                    indexes[j] = i;
                }
            }
        }

        return indexes;
    }
}