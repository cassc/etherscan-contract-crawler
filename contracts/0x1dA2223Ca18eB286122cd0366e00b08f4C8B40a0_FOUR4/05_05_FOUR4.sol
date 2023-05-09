/**
/** 
 * WHAT THE 4 IS?
 * https://twitter.com/cz_binance/status/1631579936531292160
 * 
 * ok I need TOKEN TO RELEASE, like VERY SOON. I cant take this anymore.
 * every day I am checking updates and it is saying the same.
 * every day, check progress, no progress.
 * I cant take this anymore, I have been waiting way too long for this.
 * it is what it is.
 * but I need the token to RELEASE ALREADY.
 * can devs DO SOMETHING??
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FOUR4 is ERC20 {
    function owner() external pure virtual returns (address) {
        // owner renounced, no owner, for the stupid dextools
        return address(0);
    }

    constructor() ERC20("FOUR4CZ", "FOUR4") {
        _mint(msg.sender, 444444444444 * 10 ** decimals());
    }
}