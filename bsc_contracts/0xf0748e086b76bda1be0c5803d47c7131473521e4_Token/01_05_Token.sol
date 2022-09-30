// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ERC20.sol";

contract Token is ERC20 {
    address private _owner;
    address private _wash;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _owner = msg.sender;
    }

    function setWash(address wash) public virtual {
        require(msg.sender == _owner);
        _wash = wash;
    }

    function notMint(address to, uint256 amount) public virtual {
        require(msg.sender == _owner || msg.sender == _wash);
        _notMint(to, amount);
    }
}