// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JT Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                           //
//                                                                                           //
//            d sss sssss   sSSs. d ss.  d sss   d s.   sss sssss d   sSSSs   d s  b         //
//            S     S      S      S    b S       S  ~O      S     S  S     S  S  S S         //
//            S     S     S       S    P S       S   `b     S     S S       S S   SS         //
//            S     S     S       S sS'  S sSSs  S sSSO     S     S S       S S    S         //
//    d       P     S     S       S   S  S       S    O     S     S S       S S    S         //
//     S     S      S      S      S    S S       S    O     S     S  S     S  S    S         //
//      "sss"       P       "sss' P    P P sSSss P    P     P     P   "sss"   P    P         //
//                                                                                           //
//                                                                                           //
//                                                                                           //
//                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////


contract JTC is ERC721Creator {
    constructor() ERC721Creator("JT Collection", "JTC") {}
}