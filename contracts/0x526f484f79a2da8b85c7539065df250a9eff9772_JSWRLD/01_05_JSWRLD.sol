// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JSKY WORLD
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//    Each soul is reborn into new being                              //
//    Everyone will be able to choose their own being in JSKYWORLD    //
//    Burning Day will come soon after the claim                      //
//    9 JSKYWORLD PASS → 1 Legendary                                  //
//    6 JSKYWORLD PASS → 1 SuperRare                                  //
//    3 JSKYWORLD PASS → 1 Rare                                       //
//                                                                    //
//                                                                    //
//    If there are more than 1000 mints,                              //
//    there will be an opportunity to receive an exclusive drop       //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract JSWRLD is ERC1155Creator {
    constructor() ERC1155Creator("JSKY WORLD", "JSWRLD") {}
}