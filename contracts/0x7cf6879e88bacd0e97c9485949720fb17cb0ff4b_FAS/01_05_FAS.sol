// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Find ART Society
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                       //
//                                                                                                                       //
//                                                                                                                       //
//    d sss  d d s  b d ss         d s.   d ss.  sss sssss        sss.   sSSSs     sSSs. d d sss   sss sssss Ss   sS     //
//    S      S S  S S S   ~o       S  ~O  S    b     S          d       S     S   S      S S           S       S S       //
//    S      S S   SS S     b      S   `b S    P     S          Y      S       S S       S S           S        S        //
//    S sSSs S S    S S     S      S sSSO S sS'      S            ss.  S       S S       S S sSSs      S        S        //
//    S      S S    S S     P      S    O S   S      S               b S       S S       S S           S        S        //
//    S      S S    S S    S       S    O S    S     S               P  S     S   S      S S           S        S        //
//    P      P P    P P ss"        P    P P    P     P          ` ss'    "sss"     "sss' P P sSSss     P        P        //
//                                                                                                                       //
//                                                                                                                       //
//                                                                                                                       //
//                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FAS is ERC1155Creator {
    constructor() ERC1155Creator("Find ART Society", "FAS") {}
}