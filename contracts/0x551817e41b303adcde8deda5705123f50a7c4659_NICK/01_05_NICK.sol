// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Vizualsbynick
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                //
//                                                                                                //
//    Yb    dP 88 8888P 88   88    db    88     .dP"Y8 88""Yb Yb  dP 88b 88 88  dP""b8 88  dP     //
//     Yb  dP  88   dP  88   88   dPYb   88     `Ybo." 88__dP  YbdP  88Yb88 88 dP   `" 88odP      //
//      YbdP   88  dP   Y8   8P  dP__Yb  88  .o o.`Y8b 88""Yb   8P   88 Y88 88 Yb      88"Yb      //
//       YP    88 d8888 `YbodP' dP""""Yb 88ood8 8bodP' 88oodP  dP    88  Y8 88  YboodP 88  Yb     //
//                                                                                                //
//                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////


contract NICK is ERC721Creator {
    constructor() ERC721Creator("Vizualsbynick", "NICK") {}
}