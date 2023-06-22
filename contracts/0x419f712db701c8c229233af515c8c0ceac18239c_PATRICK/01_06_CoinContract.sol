// SPDX-License-Identifier: MIT
import "./ERC20.sol";

pragma solidity ^0.8.4;
contract PATRICK is ERC20 {
    constructor() ERC20("Patrick Star", "PATRICK") {
        _mint(msg.sender, 3_010_000_000_000 * 10**uint(decimals()));
    }
}