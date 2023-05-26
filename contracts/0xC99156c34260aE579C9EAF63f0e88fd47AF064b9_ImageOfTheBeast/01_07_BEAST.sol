// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @custom:security-contact [email protected]
contract ImageOfTheBeast is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Image of the Beast", "BEAST") {
        _mint(msg.sender, 299792458 * 10 ** decimals());
    }
}