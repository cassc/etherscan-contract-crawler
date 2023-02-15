// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HA is ERC20, Ownable {
    constructor() ERC20("HA", "HA") {
        _mint(0x1b1Aa557aD095f057520321a305a5b3A5C721a90, 1 * 10 ** decimals());
        _mint(
            0x744c9D9C577b807e901352C71f5a308017339177,
            (100000000 - 1) * 10 ** decimals()
        );
    }
}