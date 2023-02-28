// SPDX-License-Identifier: MIT
/*
    STO Token was the weirdest thing you saw for a while.
    Sadge, it's rugged...then Jeet STO Inu rekt.
    
    Here's a legit one. Let's make a community TG and figure out together WTF was STO fr.
    And get the guy who bought 150ETH to pamp this shit.
*/

pragma solidity 0.8.7;

import "ERC20.sol";

contract STO is ERC20 {
    constructor() ERC20("STO Token", "STO"){
        _mint(msg.sender, 1_000_000_000 * 10 ** 18);
    }
}