//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./NieuxPaymentSplitter.sol";

contract NieuxSocietyRoyaltiesSplitter is NieuxPaymentSplitter {
    constructor(
        address[] memory payees_,
        uint256[] memory shares
    ) NieuxPaymentSplitter(payees_, shares) { }
}