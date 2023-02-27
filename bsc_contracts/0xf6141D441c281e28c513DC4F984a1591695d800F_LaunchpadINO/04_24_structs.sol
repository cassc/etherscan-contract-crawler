// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import '../interfaces/ILevelManager.sol';

struct Inventory {
    mapping(bytes32 => uint256) index;
    InventoryItem[] items;
}

struct InventoryItem {
    bytes32 id;
    uint256 supply; // integer
    uint256 price; // in wei
    uint256 limit; // integer
    uint256 sold; // integer
    uint256 raised; // in wei
}

struct LevelsState {
    ILevelManager levelManager;
    bool levelsEnabled; // true
    bool forceLevelsOpenAll;
    bool lockOnRegister; // true
    // Sum of weights (lottery losers are subtracted when picking winners) for base allocation calculation
    uint256 totalWeights;
    // Base allocation is 1x in CURRENCY (different to LaunchpadIDO)
    uint256 baseAllocation;
    // 0 - all levels, 6 - starting from "associate", etc
    uint256 minAllowedLevelMultiplier;
    // Min allocation in CURRENCY after registration closes. If 0, then ignored (different to LaunchpadIDO)
    // Needs to be limited to the lowest price in items, if it drops lower than the cheapest item, no purchase can be done
    uint256 minBaseAllocation;
    // Addresses per level
    mapping(string => address[]) levelAddresses;
    // Whether (and how many) winners were picked for a lottery level
    mapping(string => address[]) levelWinners;
    // Needed for user allocation calculation = baseAllocation * userWeight
    // If user lost lottery, his weight resets to 0 - means user can't participate in sale
    mapping(address => uint256) userWeight;
    mapping(address => string) userLevel;
}