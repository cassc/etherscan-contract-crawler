// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {ERC20, ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ILoot} from './ILoot.sol';
import {LOOT_MAX_MINT, LOOT_MAX_SUPPLY} from './Constants.sol';

error AmountExceedsMaxMint();

contract Loot is ERC20Burnable, ILoot, Ownable {

    constructor() ERC20("Loot", "LOOT") { }


    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    function mint(address account, uint256 amount) external onlyOwner {
        if (amount > LOOT_MAX_MINT) {
            amount = LOOT_MAX_MINT;
        }

        if (totalSupply() + amount > LOOT_MAX_SUPPLY) {
            revert AmountExceedsMaxMint();
        }

        _mint(account, amount);
    }
}