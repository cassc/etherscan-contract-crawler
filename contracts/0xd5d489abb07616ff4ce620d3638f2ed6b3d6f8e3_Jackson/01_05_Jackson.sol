// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Jackson is ERC20 {

    uint256 public MAX_SUPPLY = 1_000_000_000 ether;

    constructor() ERC20("Jackson", "Jackson"){
        _mint(address(this), MAX_SUPPLY);
        _transfer(address(this), msg.sender, MAX_SUPPLY);
    }
}