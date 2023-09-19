// SPDX-License-Identifier: MIT
import "./ERC20.sol";
/*
https://twitter.com/DORAEMONONCHAIN
https://t.me/DORAEMONonChain
https://doraemononeth.xyz
*/

pragma solidity ^0.8.4;
contract DoraemonToken is ERC20, Ownable {
    constructor() ERC20("Doraemon", "DORAEMON") {
        _mint(msg.sender, 6_010_000_000_000 * 10**uint(decimals()));
    }
}