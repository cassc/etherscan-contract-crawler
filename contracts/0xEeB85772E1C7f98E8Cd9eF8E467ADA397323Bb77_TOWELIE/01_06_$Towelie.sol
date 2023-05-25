/**

t.me/towelie_token_eth
twitter.com/Towelie_Token
towelietoken.vip

*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TOWELIE is ERC20, Ownable {
    constructor() ERC20("TOWELIE", "$TOWELIE") {
        _mint(msg.sender, 420420420420 * 10 ** decimals());
    }
}