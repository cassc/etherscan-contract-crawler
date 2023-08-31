// SPDX-License-Identifier: MIT
import "./ERC20.sol";
/*
https://twitter.com/PEBUonETH
https://t.me/PEBUETH
https://pepebulleth.xyz
*/

pragma solidity ^0.8.4;
contract PepeBullToken is ERC20, Ownable {
    constructor() ERC20("Pepe Bull", "PEBU") {
        _mint(msg.sender, 6_010_000_000_000 * 10**uint(decimals()));
    }
}