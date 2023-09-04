//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract TMR is ERC20 {

    constructor() ERC20("Tomorrow", "TMR") {
        _mint(msg.sender, 10000000000 * 10**uint(decimals()));
    }

}