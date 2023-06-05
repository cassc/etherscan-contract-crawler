// SPDX-License-Identifier: UNLICENSED

//offical token by ben.eth
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Loyaltoken is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Loyal", "LOYAL") {
        _mint(msg.sender, 100000000000 * 10 ** decimals());
    }
}