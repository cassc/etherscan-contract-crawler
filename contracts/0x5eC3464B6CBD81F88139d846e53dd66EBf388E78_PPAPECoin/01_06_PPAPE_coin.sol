// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @custom:security-contact [email protected]
contract PPAPECoin is ERC20, Ownable {
    constructor() ERC20("PPAPECoin", "PPAPE") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}