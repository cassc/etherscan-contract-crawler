// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: thingsfromSTEINFARM
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                                                                       //
//                         thingsfromsteinfarm                           //
//    01110100 01101000 01101001 01101110 01100111 01110011 01100110     //
//    01110010 01101111 01101101 01110011 01110100 01100101 01101001     //
//             01101110 01100110 01100001 01110010 01101101              //
//                                                                       //
//                                                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////


contract TFSF is ERC1155Creator {
    constructor() ERC1155Creator("thingsfromSTEINFARM", "TFSF") {}
}