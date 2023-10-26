// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "./ERC20.sol";


contract JaredFromSubway is ERC20 {
    constructor() ERC20("JaredFromSubway", "LGBTQIA") {
        _mint(msg.sender, 88_088_088_000 * 10 ** 18);
    }
}