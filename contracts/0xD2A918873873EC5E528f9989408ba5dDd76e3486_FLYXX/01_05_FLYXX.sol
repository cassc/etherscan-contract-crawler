// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FLYOSITY  ❰ × ❱  1/1s
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//    888888 88     Yb  dP  dP"Yb  .dP"Y8 88 888888 Yb  dP     //
//    88__   88      YbdP  dP   Yb `Ybo." 88   88    YbdP      //
//    88""   88  .o   8P   Yb   dP o.`Y8b 88   88     8P       //
//    88     88ood8  dP     YbodP  8bodP' 88   88    dP        //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract FLYXX is ERC721Creator {
    constructor() ERC721Creator(unicode"FLYOSITY  ❰ × ❱  1/1s", "FLYXX") {}
}