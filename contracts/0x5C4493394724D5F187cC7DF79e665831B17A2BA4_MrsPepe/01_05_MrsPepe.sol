// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MrsPepe is ERC20 {

    constructor() ERC20("MrsPepe", "MRSPEPE") {
        _mint(msg.sender, 420000000000 ether);
    }

}