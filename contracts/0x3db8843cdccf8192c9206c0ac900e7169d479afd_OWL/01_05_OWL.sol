// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PEPE IN WEB3
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//    PEPE is kind of bored in the WEB2,    //
//    That is why he joined WEB3.           //
//    *BLINK* ;)                            //
//    Watch until the end                   //
//                                          //
//                                          //
//////////////////////////////////////////////


contract OWL is ERC721Creator {
    constructor() ERC721Creator("PEPE IN WEB3", "OWL") {}
}