// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BEP20.sol";

contract AnvilCoin is BEP20 {
    constructor() BEP20("AnvilCoin", "AVC", 1000000000 ether, 100000000 ether) {
    }
}

contract BoostUSD is BEP20 {
    constructor() BEP20("BoostUSD", "BUSD", 1000000000 ether, 100000000 ether) {
    }
}