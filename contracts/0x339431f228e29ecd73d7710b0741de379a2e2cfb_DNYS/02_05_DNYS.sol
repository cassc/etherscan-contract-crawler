// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "./ERC20.sol";

contract DNYS is ERC20 {
    constructor() ERC20("Dionysus", "DNYS") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}