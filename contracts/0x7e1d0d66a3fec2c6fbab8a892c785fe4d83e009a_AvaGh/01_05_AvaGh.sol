// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ava Ghayoumi Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//       db    Yb    dP    db         dP""b8 88  88    db    Yb  dP  dP"Yb  88   88 8b    d8 88     //
//      dPYb    Yb  dP    dPYb       dP   `" 88  88   dPYb    YbdP  dP   Yb 88   88 88b  d88 88     //
//     dP__Yb    YbdP    dP__Yb      Yb  "88 888888  dP__Yb    8P   Yb   dP Y8   8P 88YbdP88 88     //
//    dP""""Yb    YP    dP""""Yb      YboodP 88  88 dP""""Yb  dP     YbodP  `YbodP' 88 YY 88 88     //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract AvaGh is ERC1155Creator {
    constructor() ERC1155Creator("Ava Ghayoumi Editions", "AvaGh") {}
}