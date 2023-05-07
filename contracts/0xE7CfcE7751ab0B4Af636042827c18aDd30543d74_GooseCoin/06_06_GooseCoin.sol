// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";


contract GooseCoin is ERC20Capped {
    address public owner;

    // 69 Trillion 420 Billion
    uint256 public cappedSupply = 69420000000000 * (10 ** decimals());

    constructor() ERC20("GooseCoin", "GOOSE") ERC20Capped(cappedSupply) {
        owner = msg.sender;
        
        _mint(owner, cappedSupply);
    }
}