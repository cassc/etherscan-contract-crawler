// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract WarOnCrypto is ERC20, ERC20Burnable, ERC20Permit {
    constructor() ERC20("War On Crypto", "WOC") ERC20Permit("War On Crypto") {
        _mint(msg.sender, 2 * 10**9 * 10**decimals());
    }
}