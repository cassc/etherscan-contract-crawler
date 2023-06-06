//
//   /$$$$$$                       /$$$$$$
//  /$$__  $$                     /$$__  $$
// | $$  \ $$  /$$$$$$   /$$$$$$ | $$  \ $$  /$$$$$$   /$$$$$$
// | $$$$$$$$ /$$__  $$ /$$__  $$| $$  | $$ /$$__  $$ /$$__  $$
// | $$__  $$| $$  \ $$| $$$$$$$$| $$  | $$| $$  \ $$| $$  \ $$
// | $$  | $$| $$  | $$| $$_____/| $$  | $$| $$  | $$| $$  | $$
// | $$  | $$| $$$$$$$/|  $$$$$$$|  $$$$$$/| $$$$$$$/| $$$$$$$/
// |__/  |__/| $$____/  \_______/ \______/ | $$____/ | $$____/
//           | $$                          | $$      | $$
//           | $$                          | $$      | $$
//           |__/                          |__/      |__/
//
// The Ape Opportunities Coin is the pure and uncluttered apeing coin,
// designed for enthusiastic apes.
//
// ApeOpp is for those greedy apes who don’t care about blockchain technology
// or the functional value of protocols.
// It’s only value is to provide you with the excitement and exhilaration
// you only achieve by apeing into the latest sh%7coin.
//
// We're tired of looking for the perfect opportunity to APE into, so we developed our own,
// here’s how it works:
// - ApeOpp is launched in week one.
// - No TAX
// - No Blacklist / Whitelist
// - No Limits
// - No backdoors or blocks in contract, simple and safe
// - No contract owner
// - No rugpulls
// - Total supply used for initial LP
// - Initial liquidity is locked until 6/9/23 1:00:00 AM UTC
// - You have one week to enjoy Apeing into and trading ApeOpp.
// - At the end of week one, the following happens:
//      - Initial liquidity pulled out by ApeOpp devs
//      - ApeOpp tokens from LP are burned
//      - Anyone holding ApeOpp after this qualifies as a Proper Ape
//      - Proper Apes will be eligible for something special ...
//
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract ApeOpp is ERC20, ERC20Burnable {
    constructor() ERC20("Ape Opportunities", "ApeOpp") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}