// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: a pointless exploration
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//    sss sssss d    d d sss     sss. d sss        d d s   sb d s.     sSSSs   d sss     sss.      d    d d s.   d    b d sss        d s  b   sSSSs                  //
//        S     S    S S       d      S            S S  S S S S  ~O   S     S  S       d           S    S S  ~O  S    S S            S  S S  S     S                 //
//        S     S    S S       Y      S            S S   S  S S   `b S         S       Y           S    S S   `b S    S S            S   SS S       S                //
//        S     S sSSS S sSSs    ss.  S sSSs       S S      S S sSSO S         S sSSs    ss.       S sSSS S sSSO S    S S sSSs       S    S S       S                //
//        S     S    S S            b S            S S      S S    O S    ssSb S            b      S    S S    O S    S S            S    S S       S                //
//        S     S    S S            P S            S S      S S    O  S     S  S            P      S    S S    O  S   S S            S    S  S     S                 //
//        P     P    P P sSSss ` ss'  P sSSss      P P      P P    P   "sss"   P sSSss ` ss'       P    P P    P   "ssS P sSSss      P    P   "sss"                  //
//                                                                                                                                                                   //
//    d ss    d sss     sss.   sSSs. d ss.  d d ss.  sss sssss d   sSSSs   d s  b                                                                                    //
//    S   ~o  S       d       S      S    b S S    b     S     S  S     S  S  S S                                                                                    //
//    S     b S       Y      S       S    P S S    P     S     S S       S S   SS                                                                                    //
//    S     S S sSSs    ss.  S       S sS'  S S sS'      S     S S       S S    S                                                                                    //
//    S     P S            b S       S   S  S S          S     S S       S S    S .ss                                                                                //
//    S    S  S            P  S      S    S S S          S     S  S     S  S    S SSSz                                                                               //
//    P ss"   P sSSss ` ss'    "sss' P    P P P          P     P   "sss"   P    P 'ZZ'                                                                               //
//                                                                                                                                                                   //
//    sss sssss d    d d sss   Ss   sS      d    d d s.   d    b d sss        d s  b   sSSSs        d ss.  d       b d ss.  d ss.    sSSSs     sss. d sss            //
//        S     S    S S         S S        S    S S  ~O  S    S S            S  S S  S     S       S    b S       S S    b S    b  S     S  d      S                //
//        S     S    S S          S         S    S S   `b S    S S            S   SS S       S      S    P S       S S    P S    P S       S Y      S                //
//        S     S sSSS S sSSs     S         S sSSS S sSSO S    S S sSSs       S    S S       S      S sS'  S       S S sS'  S sS'  S       S   ss.  S sSSs           //
//        S     S    S S          S         S    S S    O S    S S            S    S S       S      S      S       S S   S  S      S       S      b S       .ss      //
//        S     S    S S          S         S    S S    O  S   S S            S    S  S     S       S       S     S  S    S S       S     S       P S       SSSz     //
//        P     P    P P sSSss    P         P    P P    P   "ssS P sSSss      P    P   "sss"        P        "sss"   P    P P        "sss"   ` ss'  P sSSss 'ZZ'     //
//                                                                                                                                                                   //
//    sss sssss d    d d sss   Ss   sS        sss. d d s   sb d ss.  d      Ss   sS      d s.   d ss.  d sss                                                         //
//        S     S    S S         S S        d      S S  S S S S    b S        S S        S  ~O  S    b S                                                             //
//        S     S    S S          S         Y      S S   S  S S    P S         S         S   `b S    P S                                                             //
//        S     S sSSS S sSSs     S           ss.  S S      S S sS'  S         S         S sSSO S sS'  S sSSs                                                        //
//        S     S    S S          S              b S S      S S      S         S         S    O S   S  S       .ss                                                   //
//        S     S    S S          S              P S S      S S      S         S         S    O S    S S       SSSz                                                  //
//        P     P    P P sSSss    P         ` ss'  P P      P P      P sSSs    P         P    P P    P P sSSss 'ZZ'                                                  //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract APE is ERC721Creator {
    constructor() ERC721Creator("a pointless exploration", "APE") {}
}