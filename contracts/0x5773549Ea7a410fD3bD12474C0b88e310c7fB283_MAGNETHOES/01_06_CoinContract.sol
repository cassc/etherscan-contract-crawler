// SPDX-License-Identifier: MIT
import "./ERC20.sol";

pragma solidity ^0.8.4;
contract MAGNETHOES is ERC20 {
    constructor() ERC20("Magnet Hoes", "MAGNETHOES") {
        _mint(msg.sender, 1_010_000_000_000 * 10**uint(decimals()));
    }
}