// SPDX-License-Identifier: MIT
import "./ERC20.sol";

pragma solidity ^0.8.4;
contract DONALD is ERC20 {
    constructor() ERC20("Donald Duck", "DONALD") {
        _mint(msg.sender, 4_010_000_000_000 * 10**uint(decimals()));
    }
}