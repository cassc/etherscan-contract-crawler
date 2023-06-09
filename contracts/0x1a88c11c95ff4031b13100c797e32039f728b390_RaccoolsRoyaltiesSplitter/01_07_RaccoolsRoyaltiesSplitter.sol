// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";


contract RaccoolsRoyaltiesSplitter is PaymentSplitter {
    uint256[] private teamShares = [40, 30, 30];
    address[] private team = [
        0x70B4AbB819570055C60D215F16F2765cEec144c5,
        0x0000D385e5DB73289B3F515b65e6cac6707Ac390,
        0x5cc61632E181903cF2f476c420bF781F6ee53059
    ];

    constructor() PaymentSplitter(team, teamShares) {}
}