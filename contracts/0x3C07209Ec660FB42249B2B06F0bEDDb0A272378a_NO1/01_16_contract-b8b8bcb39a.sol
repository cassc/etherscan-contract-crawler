// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20FlashMint.sol";

contract NO1 is ERC20, ERC20Burnable, Ownable, ERC20Permit, ERC20FlashMint {
    constructor() ERC20("NO1", "NO1") ERC20Permit("NO1") {
        _mint(msg.sender, 5000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}