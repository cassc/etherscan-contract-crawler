// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SHIT is ERC20{
    constructor() ERC20("Shitmeme", "SHIT"){
         _mint(msg.sender,420690000001*10**18);
    }
}