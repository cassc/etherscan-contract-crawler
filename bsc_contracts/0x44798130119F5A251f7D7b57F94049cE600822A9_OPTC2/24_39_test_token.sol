// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TESTU is ERC20 {
    uint public time;
    constructor (string memory name) ERC20(name, name){
        _mint(msg.sender, 6000000000e18);
    }
}