// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/AccountValidator.sol";
import "./libraries/AntiWhale.sol";
import "./libraries/Recover.sol";
import "./libraries/TaxToken.sol";

contract RyiuToken is Ownable, AccountValidator, Recover, AntiWhale, TaxToken {
    string private constant NAME = "RYIU Token";
    string private constant SYMBOL = "RYIU";
    uint8 private constant DECIMALS = 9;
    uint256 private constant SUPPLY = 20 * 10 ** 6 * 10 ** 9;

    constructor(
        address swapRouter_,
        FeeConfiguration memory feeConfiguration_
    )
        ERC20Base(NAME, SYMBOL, DECIMALS)
        AntiWhale(SUPPLY / 100) /* 1% of supply */
        TaxToken(true, (SUPPLY * 5) / 10000 /* 0.05% of supply */, swapRouter_, feeConfiguration_)
        RewardToken(SUPPLY)
    {
        // configure addresses excluded from rewards
        _setIsExcludedFromRewards(swapPair, true);
        _setIsExcludedFromRewards(BURN_ADDRESS, true);

        // configure addresses excluded from antiwhale
        _setIsExcludedFromAntiWhale(swapPair, true);
        _setIsExcludedFromAntiWhale(BURN_ADDRESS, true);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override (ERC20Base, AccountValidator) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Base, AntiWhale) {
        super._afterTokenTransfer(from, to, amount);
    }
}