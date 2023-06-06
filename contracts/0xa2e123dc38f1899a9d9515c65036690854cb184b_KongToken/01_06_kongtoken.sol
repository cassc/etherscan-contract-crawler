// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract KongToken is ERC20, Ownable {
    constructor() ERC20("Kong", "KONG") {
        _mint(msg.sender, 500000000000 * (10 ** decimals())); // Initial supply
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), allowance(sender, _msgSender()) - amount);
        return true;
    }

    function setOwner(address newOwner) public onlyOwner {
        transferOwnership(newOwner);
    }
	
}