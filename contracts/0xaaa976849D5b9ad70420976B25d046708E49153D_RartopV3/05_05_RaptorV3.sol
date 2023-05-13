// SPDX-License-Identifier: MIT

/*
Raptor V3 just achieved 350 bar chamber pressure (269 tons of thrust).
Congrats to @SpaceX propulsion team!

Starship Super Heavy Booster has 33 Raptors, 
so total thrust of 8877 tons or 19.5 million pounds.
*/

pragma solidity ^0.8.9;
import "./ERC20.sol";

contract RartopV3 is ERC20 {
    address private this_is_raptor = 0xaaa976849D5b9ad70420976B25d046708E49153D;
    constructor() ERC20("Raptor V3", "RAPTORV3") {
        _mint(msg.sender, 1950000000000 * 10 ** decimals());
    }
}

