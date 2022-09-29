// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract SPORT is ERC20, ERC20Burnable {
    constructor() ERC20("ERC20 Token Sample2", "Sample 2") {
        _mint(msg.sender, 100_000_000_000 * 10**18 );
    }
}