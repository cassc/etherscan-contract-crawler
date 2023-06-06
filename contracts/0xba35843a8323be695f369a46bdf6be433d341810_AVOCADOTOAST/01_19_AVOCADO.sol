// https://t.me/AvocadoToastErc20

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract AVOCADOTOAST is ERC20, ERC20Burnable, ERC20Permit, Ownable {
    constructor()
        ERC20("AVOCADO TOAST", "$AVOCADO")
        ERC20Permit("AVOCADO TOAST")
    {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}