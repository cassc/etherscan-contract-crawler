/**
Fetch Your Future

Drawing inspiration from the timeless game of fetch, we establish a robust connection between the digital realm and the loyalty of dogs. 
By intertwining the magnetism of dogs with modern digital aspects, FETCH aspires to create a distinctive community, united by dedication, trust, and shared progress.

https://fetcherc20.pro	https://t.me/FETCHPortal https://twitter.com/FETCH_ERC20

**/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FETCH is ERC20 {
    constructor() ERC20("FETCH", "FETCH") {
        _mint(msg.sender, 1_000_000_000 * 10**18);
    }
}