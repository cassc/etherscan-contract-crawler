// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/draft-ERC20Permit.sol";

contract PepetoshiNakamoto is ERC20, ERC20Burnable, ERC20Permit {
    constructor()
        ERC20("Pepetoshi Nakamoto", "PEPET")
        ERC20Permit("Pepetoshi Nakamoto")
    {
        _mint(msg.sender, 21000000000 * 10 ** decimals());
    }
}