// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title A PlanetexToken, symbol TPTX

// allocations
// Pre-sale - 7%
// Main Sale - 6%
// Private Sale - 3%
// IDO - 9%
// Team - 10%
// Advisors - 2,5%
// Launchpad - 0,5%
// Airdrop & Marketing - 15%
// Treasury - 20%
// Liquidity - 10%
// Ecosistem - 10%
// Platform Reward (Staking, etc.) - 7%

contract PlanetexToken is ERC20, Ownable {
    uint256 public immutable PRECISSION = 1000;

    error InvalidArrayLengths(string err);
    error ZeroAddress(string err);
    error ZeroPercent(string err);

    constructor(
        address[] memory recipients,
        uint256[] memory percents,
        uint256 totalSupply
    ) ERC20("PlanetexToken", "PLTEX") {
        if (recipients.length != percents.length) {
            revert InvalidArrayLengths("PlanetexToken: Invalid array lengths");
        }
        for (uint256 i; i <= recipients.length - 1; i++) {
            if (percents[i] == 0) {
                revert ZeroPercent("PlanetexToken: Zero percent");
            }
            if (recipients[i] == address(0)) {
                revert ZeroAddress("PlanetexToken: Zero address");
            }
            uint256 mintAmount = (totalSupply * percents[i]) / PRECISSION;
            _mint(recipients[i], mintAmount);
        }
    }
}