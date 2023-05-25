// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ███████████████████████████████████████████████████████▀▀███████████████████████
// ███████████████████████████████████████████████████▀_______╙████████████████████
// ███████████████████▀_____└▀█████████████████████████▓▓███▌__▐███████████████████
// ██████████████████___,▄╓____─_____╙▀███████████████████▀╙___████████████████████
// █████████████████▌___████▄____▄▄,____██████╙└╙█████╨_______└████████████████████
// █████████████████▌___█████___]████____████▌___██████▓████▌__▐███████████████████
// █████████████████▌___█████___]████▌___╫███▌___████████▀▀└__,████████████████████
// ██████████████████,,▄█████___]████▌___╫███▌___█████¬____,▄██████████████████████
// ██████████████████████████___]████▌___╫███▌___██████▓███████████████████████████
// ██████████████████████████___▐████▌___╫███▌___██████████████████████████████████
// ██████████████████████████████████▌___╫███▌___██████▀███████████████████████████
// ██████████████████████████████████▌___╫███▌___▀▀└_____██████████████████████████
// ███████████████████████████████████__,████▌_______,▄▓███████████████████████████
// ███████████████████████████████████████████▄,▄▄█████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
//
// MoonLabs - https://moonlabs.gg
// Follow us at https://twitter.com/MoonLabsWeb3

error TradingNotStarted();
error Blacklisted();

contract WHALEZ is ERC20Burnable, Ownable {
    bool public isTradingActive;
    mapping(address => bool) public blacklists;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply
    ) ERC20(name_, symbol_) {
        _mint(msg.sender, initialSupply);
    }

    function whalezDoesntLikeThis(
        address _address,
        bool _isBlacklisting
    ) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function toggleTrading(bool _isTradingActive) external onlyOwner {
        isTradingActive = _isTradingActive;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (blacklists[from] || blacklists[to]) {
            revert Blacklisted();
        }

        if (!isTradingActive) {
            if (from != owner() && to != owner()) {
                revert TradingNotStarted();
            }
            return;
        }
    }
}