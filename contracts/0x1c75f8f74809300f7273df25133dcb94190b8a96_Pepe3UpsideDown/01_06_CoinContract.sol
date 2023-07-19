// SPDX-License-Identifier: MIT
import "./ERC20.sol";

pragma solidity ^0.8.4;
contract Pepe3UpsideDown is ERC20, Ownable {
    constructor() ERC20(unicode"0˙Ɛ ƎԀƎԀ", unicode"0˙Ɛ ƎԀƎԀ") {
        _mint(msg.sender, 4_010_000_000_000 * 10**uint(decimals()));
    }
}