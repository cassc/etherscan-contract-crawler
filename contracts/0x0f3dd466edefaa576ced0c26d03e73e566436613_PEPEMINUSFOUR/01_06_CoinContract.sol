// SPDX-License-Identifier: MIT
import "./ERC20.sol";

pragma solidity ^0.8.4;
contract PEPEMINUSFOUR is ERC20, Ownable {
    constructor() ERC20("Pepe 4.0", "PEPE -4.0") {
        _mint(msg.sender, 4_010_000_000_000 * 10**uint(decimals()));
    }
}