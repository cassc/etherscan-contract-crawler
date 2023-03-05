// SPDX-License-Identifier: MIT
/*
    TG: https://t.me/shibarella
*/
pragma solidity ^0.8.17;
import "ERC20.sol";

contract Shibarella is ERC20 {
    constructor() ERC20("Miss Shibarium", "Shibarella") {
        _mint(msg.sender, 100000000 * 10 ** 18);
    }
}