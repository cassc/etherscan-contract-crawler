// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract Anxiety is ERC20, ERC20Burnable, ERC20Permit {
    constructor() ERC20("Anxiety", "ANX") ERC20Permit("Anxiety") {        
        _mint(msg.sender, 1* 10**9 * 10 ** decimals());
    }
}