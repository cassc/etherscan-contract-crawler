//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import "@ensdomains/ens-contracts/contracts/reverseRegistrar/ReverseClaimer.sol";

contract Contract is ReverseClaimer {
    constructor (
        ENS ens
    ) ReverseClaimer(ens, msg.sender) {}
}