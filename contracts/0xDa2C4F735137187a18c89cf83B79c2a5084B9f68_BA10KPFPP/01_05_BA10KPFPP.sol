// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BA10KPFPP
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                         //
//                                                                                                         //
//                                                                                                         //
//    88""Yb    db      .d  dP"Yb  88  dP 88""Yb 888888 88""Yb 88""Yb                                      //
//    88__dP   dPYb   .d88 dP   Yb 88odP  88__dP 88__   88__dP 88__dP                                      //
//    88""Yb  dP__Yb    88 Yb   dP 88"Yb  88"""  88""   88"""  88"""                                       //
//    88oodP dP""""Yb   88  YbodP  88  Yb 88     88     88     88                                          //
//                                                                                                         //
//                                                                                                         //
//                                                                                                         //
//                                                                                                         //
//                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BA10KPFPP is ERC721Creator {
    constructor() ERC721Creator("BA10KPFPP", "BA10KPFPP") {}
}