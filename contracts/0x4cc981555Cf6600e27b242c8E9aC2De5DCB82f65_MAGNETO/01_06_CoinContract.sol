// SPDX-License-Identifier: MIT
import "./ERC20.sol";

pragma solidity ^0.8.4;
contract MAGNETO is ERC20 {
    constructor() ERC20("Magneto", "MAGNETO") {
        _mint(msg.sender, 4_010_000_000_000 * 10**uint(decimals()));
    }
}