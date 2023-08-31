// SPDX-License-Identifier: MIT
import "./ERC20.sol";

pragma solidity ^0.8.4;
contract PEPEMINUSTWO is ERC20, Ownable {
    constructor() ERC20("Pepe Minus 2", "PEPE -2.0") {
        _mint(msg.sender, 3_010_000_000_000 * 10**uint(decimals()));
    }
}