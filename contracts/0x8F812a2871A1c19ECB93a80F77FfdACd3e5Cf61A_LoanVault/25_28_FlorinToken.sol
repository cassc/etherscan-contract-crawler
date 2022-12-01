// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/// @title FlorinToken
/// @dev The FlorinToken is the base currency for the protocol and its LoanVaults
contract FlorinToken is ERC20PermitUpgradeable, ERC20BurnableUpgradeable, OwnableUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {} // solhint-disable-line

    function initialize() external initializer {
        __ERC20_init_unchained("Florin", "FLR");
        __ERC20Permit_init("Florin");
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    /// @dev Mints FLR. Protected, only be callable by owner which should be FlorinTreasury
    /// @param receiver receiver of the minted FLR
    /// @param amount amount to mint (18 decimals)
    function mint(address receiver, uint256 amount) public onlyOwner {
        require(amount > 0, "mint amount must be > 0");
        _mint(receiver, amount);
    }
}