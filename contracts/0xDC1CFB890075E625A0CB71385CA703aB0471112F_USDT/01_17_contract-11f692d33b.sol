// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Permit.sol";

contract USDT is ERC20, Ownable, ERC20Permit {
    constructor() ERC20("USDT", "USDT") ERC20Permit("USDT") {
        _mint(msg.sender, 10000000000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}