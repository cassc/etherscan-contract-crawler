// SPDX-License-Identifier: MIT
import "./ERC20.sol";

pragma solidity ^0.8.4;
contract CHATURBATE is ERC20 {
    constructor() ERC20("CHATURBATE", "CHATURBATE") {
        _mint(msg.sender, 4_010_000_000_000 * 10**uint(decimals()));
    }
}