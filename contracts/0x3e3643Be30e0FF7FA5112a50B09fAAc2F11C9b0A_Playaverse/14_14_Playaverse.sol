// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract Playaverse is ERC20, ERC20Burnable, Ownable, ERC20Permit {
    uint256 constant MAX_SUPPLY = 100000000 * 10 ** 18;

    constructor()
        ERC20("Playaverse", "PLV")
        ERC20Permit("Playaverse")
    {}

    function mint(address to, uint256 amount) public onlyOwner {
        require(
            (totalSupply() + amount) <= MAX_SUPPLY,
            "ERC20: Maximum supply exceeded"
        );
        _mint(to, amount);
    }
}