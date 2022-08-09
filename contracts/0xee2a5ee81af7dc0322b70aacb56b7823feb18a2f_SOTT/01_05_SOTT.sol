// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Signs of the Times
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                        //
//                                                                                                                        //
//    .dP"Y8 88  dP""b8 88b 88 .dP"Y8      dP"Yb  888888     888888 88  88 888888     888888 88 8b    d8 888888 .dP"Y8    //
//    `Ybo." 88 dP   `" 88Yb88 `Ybo."     dP   Yb 88__         88   88  88 88__         88   88 88b  d88 88__   `Ybo."    //
//    o.`Y8b 88 Yb  "88 88 Y88 o.`Y8b     Yb   dP 88""         88   888888 88""         88   88 88YbdP88 88""   o.`Y8b    //
//    8bodP' 88  YboodP 88  Y8 8bodP'      YbodP  88           88   88  88 888888       88   88 88 YY 88 888888 8bodP'    //
//                                                                                                                        //
//                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SOTT is ERC721Creator {
    constructor() ERC721Creator("Signs of the Times", "SOTT") {}
}