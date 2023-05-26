/**
  $DURIAN COIN

Durian Coin is designed to create a unique and delicious experience in
the world of cryptocurrency. It is a digital asset that combines exotic
flavor and style, offering its holders a dip into the alluring and
unusual world of durian.

Be sure to eat a durian at least once in your life. Trade the DURIAN coin
to spread the word about this stunning fruit, so everyone learns about
its incredible benefits and tastes it to discover its extraordinary taste.
 
♻️Website: https://www.duriancoin.org/
♻️Twitter: https://twitter.com/durian_coin_eth
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DurianCoin is Ownable, ERC20 {
    uint256 private constant INITIAL_SUPPLY = 8040000000 * 10 ** 18;

    constructor() ERC20("Durian Coin", "DURIAN") {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}