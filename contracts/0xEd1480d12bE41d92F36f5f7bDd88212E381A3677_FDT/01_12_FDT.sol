//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FDT is ERC20Burnable, ERC20Permit, Ownable {

    uint256 private constant SUPPLY = 1_000_000_000 * 10**18;

    constructor() ERC20("FIAT DAO Token", "FDT") ERC20Permit("FDT") {
        _mint(msg.sender, SUPPLY);
    }

    function mint(address to, uint256 amount) public virtual onlyOwner {
        _mint(to, amount);
    }
}