// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract AntiLPSniperUpgradeable is OwnableUpgradeable {
    bool public antiSniperEnabled;
    mapping(address => bool) public isBlackListed;
    bool public tradingOpen;

    function banHammer(address user) internal {
        isBlackListed[user] = true;
    }

    function updateBlacklist(address user, bool shouldBlacklist) external onlyOwner {
        isBlackListed[user] = shouldBlacklist;
    }

    function enableAntiSniper(bool enabled) external onlyOwner {
        antiSniperEnabled = enabled;
    }

    function openTrading() external virtual onlyOwner {
        require(!tradingOpen, "Trading already open");
        tradingOpen = !tradingOpen;
    }
}