/* @author
 * ___ ___   ___    ___   ____    ____  ____   ___  _       ____  ____
 * |   |   | /   \  /   \ |    \  /    ||    \ /  _]| |     /    ||    \
 * | _   _ ||     ||     ||  _  ||  o  ||  o  )  [_ | |    |  o  ||  o  )
 * |  \_/  ||  O  ||  O  ||  |  ||     ||   _/    _]| |___ |     ||     |
 * |   |   ||     ||     ||  |  ||  _  ||  | |   [_ |     ||  _  ||  O  |
 * |   |   ||     ||     ||  |  ||  |  ||  | |     || end ||  |  || re  |
 * |___|___| \___/  \___/ |__|__||__|__||__| |_____||_____||__|__||_____|
 *
 */
// Super simple token contract inspired by the ApeCoin
// All logic is elsewhere 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MADCoin is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply_
    ) ERC20(name, symbol) {
        _mint(msg.sender, totalSupply_);
    }
}