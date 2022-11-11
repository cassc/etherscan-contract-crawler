// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract RoyaltiesSplitter is PaymentSplitter {
    constructor(address[] memory payees_, uint256[] memory shares_)
        PaymentSplitter(payees_, shares_)
    {}
}

// 5% Marec: 0xA92A9268B82c3cC37e4a38D7355D35cF7A442Bf8
// 5% Bozzo: 0xd418D38bb19338FC32E91Be5683F2D3F842De92f
// 5% Maxim: 0x579E9035Bf45A94c9EE79Fa3f12eCA91CE6717B9
// 5% Salom: 0x602a104CD591C11bF3c2081C8D635D7123296280
// 35% MNV: 0x1Bb807B0AD0d43893f6902Efdd4b568A15368122
// 35% Occc: 0xa314Eb02bA53A415D09a2098D9A0D1D0C455a81a
// 10% Sopr: 0x379FE33635532c4f8D1AE50391f7dDF5b32B4C36