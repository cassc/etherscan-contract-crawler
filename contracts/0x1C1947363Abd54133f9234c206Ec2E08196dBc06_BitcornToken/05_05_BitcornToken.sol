// contracts/BitcornToken.sol
// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BitcornToken is ERC20{
    constructor() ERC20("Bitcorn", "BTN"){
        _mint(msg.sender,21000000000*10**18);
    }
}