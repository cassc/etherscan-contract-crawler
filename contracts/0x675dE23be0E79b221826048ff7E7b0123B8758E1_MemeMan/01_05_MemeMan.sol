/**

 MMM Are you ready? 

 MMM Website: mememan.io
 MMM Twitter: twitter.com/mememan_io
 MMM Telegram: t.me/mememan_io

 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MemeMan is ERC20 {
    constructor() ERC20("Meme Man", "MMM") {
        _mint(msg.sender, 420777069000 * 10 ** decimals());
    }
}