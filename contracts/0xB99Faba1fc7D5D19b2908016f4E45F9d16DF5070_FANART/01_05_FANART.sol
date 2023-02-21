// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FAN ART
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    /< /\ \/\/ /\ | | |     //
//                            //
//                            //
////////////////////////////////


contract FANART is ERC721Creator {
    constructor() ERC721Creator("FAN ART", "FANART") {}
}