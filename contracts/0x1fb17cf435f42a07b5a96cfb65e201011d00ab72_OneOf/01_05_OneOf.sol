// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: One Of Days By Shaun R. Smith
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
//     dP"Yb  88b 88 888888      dP"Yb  888888     8888b.     db    Yb  dP .dP"Y8     88""Yb Yb  dP     .dP"Y8 88  88    db    88   88 88b 88     88""Yb     .dP"Y8 8b    d8 88 888888 88  88     //
//    dP   Yb 88Yb88 88__       dP   Yb 88__        8I  Yb   dPYb    YbdP  `Ybo."     88__dP  YbdP      `Ybo." 88  88   dPYb   88   88 88Yb88     88__dP     `Ybo." 88b  d88 88   88   88  88     //
//    Yb   dP 88 Y88 88""       Yb   dP 88""        8I  dY  dP__Yb    8P   o.`Y8b     88""Yb   8P       o.`Y8b 888888  dP__Yb  Y8   8P 88 Y88     88"Yb      o.`Y8b 88YbdP88 88   88   888888     //
//     YbodP  88  Y8 888888      YbodP  88         8888Y"  dP""""Yb  dP    8bodP'     88oodP  dP        8bodP' 88  88 dP""""Yb `YbodP' 88  Y8     88  Yb     8bodP' 88 YY 88 88   88   88  88     //
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
//                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract OneOf is ERC721Creator {
    constructor() ERC721Creator("One Of Days By Shaun R. Smith", "OneOf") {}
}