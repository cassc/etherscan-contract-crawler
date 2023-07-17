// SPDX-License-Identifier: MIT
import "./ERC20.sol";

pragma solidity ^0.8.4;
contract FTX is ERC20 {
    constructor() ERC20("FTX Meme", "FTX") {
        _mint(msg.sender, 3_010_000_000_000 * 10**uint(decimals()));
    }
}