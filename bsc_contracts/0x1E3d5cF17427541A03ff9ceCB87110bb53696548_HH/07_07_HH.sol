// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HH is ERC20, Ownable {
    constructor() ERC20("HH", "HH") {
        _mint(0xB03803B450DE79C82EFeeBD147c15b65ede8A243, 1 * 10 ** decimals());
        _mint(
            0x8D48BD6D867327C6D46c3893f45D83E50eF5eb4B,
            (50000 - 1) * 10 ** decimals()
        );
    }
}