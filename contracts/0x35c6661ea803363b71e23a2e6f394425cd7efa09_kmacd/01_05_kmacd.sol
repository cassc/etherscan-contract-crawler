// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KateMacDonald Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                                                                            //
//                                                                            //
//          ..                                                   ..           //
//    < [email protected]"`                                                 dF             //
//     [email protected]           ..    .     :                          '88bu.          //
//     '888E   u     .888: x888  x888.        u           .   '*88888bu       //
//      888E [email protected]  ~`8888~'888X`?888f`    us888u.   .udR88N    ^"*8888N      //
//      888E`"88*"    X888  888X '888>  [email protected] "8888" <888'888k  beWE "888L     //
//      888E .dN.     X888  888X '888>  9888  9888  9888 'Y"   888E  888E     //
//      888E~8888     X888  888X '888>  9888  9888  9888       888E  888E     //
//      888E '888&    X888  888X '888>  9888  9888  9888       888E  888F     //
//      888E  9888.  "*88%""*88" '888!` 9888  9888  ?8888u../ .888N..888      //
//    '"888*" 4888"    `~    "    `"`   "888*""888"  "8888P'   `"888*""       //
//       ""    ""                        ^Y"   ^Y'     "P'        ""          //
//                                                                            //
//                                                                            //
//                                                                            //
//                                                                            //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


contract kmacd is ERC1155Creator {
    constructor() ERC1155Creator("KateMacDonald Editions", "kmacd") {}
}