// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "./ERC20.sol";

contract Doodlejump is ERC20 {
    uint256 private Pen = 0x0BA11A;
    constructor() ERC20("Doodle jump", "Doodle jump") {
        _mint(msg.sender, 5000000000000 * 10 ** decimals());
    }
}

