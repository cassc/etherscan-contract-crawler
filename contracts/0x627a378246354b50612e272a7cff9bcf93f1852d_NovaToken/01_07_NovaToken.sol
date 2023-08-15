// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NovaToken is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Novas Basic Token", "NBT") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount*1000000000000000000);
    }

}