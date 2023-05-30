// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Warmth in Darkness
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//    The official 1/1 contract for the collection "Warmth in Darkness"    //
//                                                                         //
//    Thank you for joining me on this journey!                            //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////


contract WiD is ERC721Creator {
    constructor() ERC721Creator("Warmth in Darkness", "WiD") {}
}