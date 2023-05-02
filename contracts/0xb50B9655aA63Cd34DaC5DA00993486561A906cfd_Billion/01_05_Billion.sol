// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Billion is ERC20 {

    constructor() ERC20("BILLION", "BILLION") {
        _mint(msg.sender, 1000000000 ether);
    }

}