// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SDD is ERC20Burnable, Ownable {
    event Mint(address to, uint256 amount);

    constructor(uint256 totalSupply) ERC20("SDD Coin", "SDD") {
        mint(msg.sender, totalSupply * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
        emit Mint(to, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }
}