// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";


contract RaccoolsRoyaltiesSplitter is PaymentSplitter {
    uint256[] private teamShares = [30,22,22,13,13];
    address[] private team = [
        0x70B4AbB819570055C60D215F16F2765cEec144c5,
        0x0000D385e5DB73289B3F515b65e6cac6707Ac390,
        0x5cc61632E181903cF2f476c420bF781F6ee53059,
        0xc73BdaFD36d5dDA350a6917ecAEf08bbEf3E8be2,
        0xf0C5864905a5D6315246825d0Bd63dC59B9eA275
    ];

    constructor() PaymentSplitter(team, teamShares) {}
}