// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ShopNEXT_Loyalty_Token is Ownable,ERC20 {
    constructor() ERC20("ShopNEXT Loyalty Token", "NEXT") {
        _mint(msg.sender, 100_000_000 * 10 ** decimals());
    }
}