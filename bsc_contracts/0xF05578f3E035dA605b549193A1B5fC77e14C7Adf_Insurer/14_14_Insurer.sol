// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract Insurer is ERC20, ERC20Burnable, Ownable, ERC20Permit {
    uint public limit = 10**6 * 10**18;
    address public _router;
    uint public x = 95 * 10**9 * 10**18;
    uint public y = 10**6 * 10**18;
    constructor(address router) ERC20("Firefox ES", "FFE") ERC20Permit("Firefox ES") {
        _router = router;
        _mint(msg.sender, 5 * 10**9 * 10**18);
    }

    modifier onlyRouter {
        require(msg.sender == _router, "Caller is not the router");
        _;
    }

    function mint(address to, uint256 amount) public onlyRouter {
        _mint(to, x - x * y / (y + amount));
        x = x * y / (y + amount);
        y += amount;
    }
    
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        if (from != address(0) && to != address(0) && amount > 0){
            _burn(to, amount / 20);
        }
    }

    function setLimit(uint _limit) public onlyOwner {
        limit = _limit;
    }

    function insured(address who) public view returns(bool c) {
        c = balanceOf(who) >= limit;
    }
}