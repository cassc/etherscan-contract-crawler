// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BCA1 is ERC20, Ownable {
    constructor(address To_) ERC20("99 problems but a coins not 1", "BCA1") {
        _mint(To_, 21000000 * 10 ** decimals());
    }
}