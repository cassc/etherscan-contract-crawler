// SPDX-License-Identifier: MIT
import "./ERC20.sol";
/*
https://t.me/PinkPepeETHcoin
https://twitter.com/PinkPepeETH
https://pinkpepecoin.xyz
*/

pragma solidity ^0.8.4;
contract PinkPepeCoin is ERC20, Ownable {
    constructor() ERC20("Pink Pepe", "PINKPEPE") {
        _mint(msg.sender, 1_000_100_000_000 * 10**uint(decimals()));
    }
}