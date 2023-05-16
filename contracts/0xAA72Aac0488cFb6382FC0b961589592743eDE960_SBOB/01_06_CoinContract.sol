// SPDX-License-Identifier: MIT
import "./ERC20.sol";

pragma solidity ^0.8.4;
contract SBOB is ERC20 {
    constructor() ERC20("Sideshow Bob", "SBOB") {
        _mint(msg.sender, 4_210_000_000_000 * 10**uint(decimals()));
    }
}