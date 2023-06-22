// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "./ERC20.sol";

contract Nvidia is ERC20 {
    constructor() ERC20("Nvidia", "NVDA") {
        _mint(msg.sender, 1062000000000 * 10 ** decimals());
    }
}

