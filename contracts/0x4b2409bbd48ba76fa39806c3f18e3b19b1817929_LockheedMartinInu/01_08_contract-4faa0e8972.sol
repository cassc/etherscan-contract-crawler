// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract LockheedMartinInu is ERC20, ERC20Burnable, Ownable {
    constructor(address initialOwner)
        ERC20("Lockheed Martin Inu", "LMI")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 100000000000000000 * 10 ** decimals());
    }
}