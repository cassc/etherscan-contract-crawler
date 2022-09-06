// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GRAFH
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    STOP CALLING ART CONTENT    //
//                                //
//                                //
////////////////////////////////////


contract SCAC is ERC721Creator {
    constructor() ERC721Creator("GRAFH", "SCAC") {}
}