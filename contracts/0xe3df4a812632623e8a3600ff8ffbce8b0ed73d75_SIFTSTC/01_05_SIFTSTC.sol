// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SIFT: STATIC
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//    through the eyes of the machine     //
//                                        //
//                                        //
////////////////////////////////////////////


contract SIFTSTC is ERC721Creator {
    constructor() ERC721Creator("SIFT: STATIC", "SIFTSTC") {}
}