// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

/// @custom:security-contact [email protected]
contract DeathOS is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("deathOS", "DEATHOS") {
        _mint(msg.sender, 25000000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}