// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract Pumpkin is ERC20, Ownable {
    constructor(address initialOwner)
        ERC20("Pumpkin ", "HEAD")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 365 * 10 ** decimals());
    }
}