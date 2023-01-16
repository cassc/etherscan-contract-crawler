// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

import {ButtPlugWars} from './ButtPlugWars.sol';

contract ChessOlympiads is ButtPlugWars {
    address constant _FIVE_OUT_OF_NINE = 0xB543F9043b387cE5B3d1F0d916E42D8eA2eBA2E0;

    constructor(address _masterOfCeremony)
        ButtPlugWars('ChessOlympiads', _masterOfCeremony, _FIVE_OUT_OF_NINE, 5 days, 4 hours)
    {}
}