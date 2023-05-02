// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: diamondsfromSTEINFARM
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////
//                                                                        //
//                                                                        //
//                         diamondsfromsteinfarm                          //
//    01100100 01101001 01100001 01101101 01101111 01101110 01100100      //
//    01110011 01100110 01110010 01101111 01101101 01110011 01110100      //
//    01100101 01101001 01101110 01100110 01100001 01110010 01101101      //
//                                                                        //
//                                                                        //
////////////////////////////////////////////////////////////////////////////


contract DFST is ERC721Creator {
    constructor() ERC721Creator("diamondsfromSTEINFARM", "DFST") {}
}