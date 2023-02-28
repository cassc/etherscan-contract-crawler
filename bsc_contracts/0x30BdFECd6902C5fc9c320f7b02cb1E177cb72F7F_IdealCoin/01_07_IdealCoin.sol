// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @custom:security-contact [email protected]
contract IdealCoin is ERC20, ERC20Burnable, Ownable {
    
    constructor() ERC20("IdealCoin", "IDEAL") {
        _mint(msg.sender, 5000000000 * 10 ** decimals());
    }

}