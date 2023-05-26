// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "./ERC20.sol";

contract Aladdin is ERC20 {
    constructor() ERC20("Aladdin", "ALADDIN") {
        _mint(msg.sender, 5000000000000 * 10 ** decimals());
    }
}

