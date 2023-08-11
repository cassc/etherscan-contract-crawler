// SPDX-License-Identifier: MIT
import "./ERC20.sol";

pragma solidity ^0.8.4;
contract Doraemon is ERC20, Ownable {
    constructor() ERC20("Doraemon", "DORAEMON") {
        _mint(msg.sender, 6_001_000_000_000 * 10**uint(decimals()));
    }
}