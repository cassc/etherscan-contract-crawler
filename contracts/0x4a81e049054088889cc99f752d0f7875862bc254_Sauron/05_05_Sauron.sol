// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "./ERC20.sol";

contract Sauron is ERC20 {
    uint256 scary_one = 0xCA11;
    constructor() ERC20("Sauron", "SAURON") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}

