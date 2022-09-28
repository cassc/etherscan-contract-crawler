//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

enum MintPhase {
    Locked,
    Allow,
    Public
}

struct Ticket {
    uint8 v;
    bytes32 r;
    bytes32 s;
}

interface BBOTSEvents {
    /*///////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    event MintPhaseSet(MintPhase phase);
    event AvailableSupplySet(uint256 amt);
    event MaxPerAddressSet(uint256 amt);
}