// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "./ERC20.sol";

contract Tiktok is ERC20 {
    constructor() ERC20("Tiktok", "TIKTOK") {
        _mint(msg.sender, 5000000000000 * 10 ** decimals());
    }
}

