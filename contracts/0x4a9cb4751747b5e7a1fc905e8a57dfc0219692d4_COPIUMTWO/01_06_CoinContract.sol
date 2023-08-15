// SPDX-License-Identifier: MIT
import "./ERC20.sol";

pragma solidity ^0.8.4;
contract COPIUMTWO is ERC20, Ownable {
    constructor() ERC20("Copium 2.0", "COPIUM2.0") {
        _mint(msg.sender, 3_010_000_000_000 * 10**uint(decimals()));
    }
}