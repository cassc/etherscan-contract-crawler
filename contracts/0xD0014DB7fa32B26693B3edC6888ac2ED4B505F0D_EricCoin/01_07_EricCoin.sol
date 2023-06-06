// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract EricCoin is ERC20, ERC20Capped, Ownable {
    
    constructor() ERC20("Eric Coin", "ERIC") ERC20Capped(1000000000000 * (10**uint256(18))) {}

    function _mint(address to, uint256 amount) internal override (ERC20,ERC20Capped)
    {
        require(totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(to, amount);
    }
    
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}