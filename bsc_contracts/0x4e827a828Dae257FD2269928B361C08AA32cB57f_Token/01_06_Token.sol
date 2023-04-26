// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract Token is ERC20Burnable{
     constructor(string memory name_, string memory symbol_, uint amount) ERC20(name_, symbol_) {
        _mint(msg.sender, 10 ** decimals() * amount);
    }
}