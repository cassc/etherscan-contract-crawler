// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
/*
IF YOU DONT LIKE SPONGE BOB OR DONALD TRUMP
THEN YOU ARE FORBIDDEN FROM BUYING THIS TOKEN.

WELCOME TO SHITTIEST SHIT COIN BIKINI BOTTOM AND
TRUMP TOWERS HAS TO OFFER.
*/
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TRUMPBOBSQUAREPANTS is ERC20 {
    constructor() ERC20("TRUMP BOB SQUARE PANTS", "TBSP") {
        _mint(msg.sender, 130000000000 * 10 ** decimals());
    }
}