// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Bored Pepe 169ERs Club
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//    sss sssss d    d d sss        d ss.    sSSSs   d ss.  d sss   d ss         d ss.  d sss   d ss.  d sss        d sss   d ss.    sss.        sSSs. d      d       b d ss.      //
//        S     S    S S            S    b  S     S  S    b S       S   ~o       S    b S       S    b S            S       S    b d            S      S      S       S S    b     //
//        S     S    S S            S    P S       S S    P S       S     b      S    P S       S    P S            S       S    P Y           S       S      S       S S    P     //
//        S     S sSSS S sSSs       S sSS' S       S S sS'  S sSSs  S     S      S sS'  S sSSs  S sS'  S sSSs       S sSSs  S sS'    ss.       S       S      S       S S sSS'     //
//        S     S    S S            S    b S       S S   S  S       S     P      S      S       S      S            S       S   S       b      S       S      S       S S    b     //
//        S     S    S S            S    P  S     S  S    S S       S    S       S      S       S      S            S       S    S      P       S      S       S     S  S    P     //
//        P     P    P P sSSss      P `SS    "sss"   P    P P sSSss P ss"        P      P sSSss P      P sSSss      P sSSss P    P ` ss'         "sss' P sSSs   "sss"   P `SS      //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
//                                                                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BPC is ERC721Creator {
    constructor() ERC721Creator("The Bored Pepe 169ERs Club", "BPC") {}
}