// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BCA1 is ERC20, Ownable {
    constructor(address To_) ERC20("99 Problems But A Coin Ain't 1", "BCA1") {
        _mint(To_, 21000000 * 10 ** decimals());
    }
}