// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Iriee
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//                                                                  //
//    8b d8 888888 .dP"Y8 dP"Yb 888888 dP"Yb 88""Yb 88 88 .dP"Y8    //
//    88b d88 88__ `Ybo." dP Yb 88 dP Yb 88__dP 88 88 `Ybo."        //
//    88YbdP88 88"" o.`Y8b Yb dP 88 Yb dP 88""" Y8 8P o.`Y8b        //
//    88 YY 88 888888 8bodP' YbodP 88 YbodP 88 `YbodP' 8bodP'       //
//                                                                  //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract DORCS is ERC721Creator {
    constructor() ERC721Creator("Iriee", "DORCS") {}
}