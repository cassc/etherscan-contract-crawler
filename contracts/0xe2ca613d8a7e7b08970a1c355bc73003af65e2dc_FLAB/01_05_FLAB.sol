// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FLAB is ERC20{
    constructor() ERC20("Flabber", "FLAB"){
        _mint(msg.sender,1000000000*10**18);
    }
}