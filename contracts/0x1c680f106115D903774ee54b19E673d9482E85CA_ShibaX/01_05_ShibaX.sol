//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract ShibaX is ERC20 {
    constructor() ERC20("Shiba Christmas", "ShibaX") {
        _mint(msg.sender, 21_000_000 * 10 ** 18);
    }
}