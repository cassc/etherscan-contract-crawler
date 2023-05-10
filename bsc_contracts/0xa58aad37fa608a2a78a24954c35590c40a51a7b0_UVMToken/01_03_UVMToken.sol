// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

import "./ERC20.sol";
import "./Owned.sol";

contract UVMToken is ERC20, Owned {

    uint256 public MAX_SUPPLY = 1804000000 ether;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) ERC20(name, symbol, decimals) Owned(msg.sender) {}

    function mint(address send_to, uint256 amount) public onlyOwner{
        require((totalSupply + amount) <= MAX_SUPPLY, 'can not mint more than max supply');
        _mint(send_to, amount);
    }
}

