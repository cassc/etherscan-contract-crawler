// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ripple&Baby
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    Ripple and her baby.    //
//    For cat lover.          //
//                            //
//                            //
////////////////////////////////


contract RAB is ERC721Creator {
    constructor() ERC721Creator("Ripple&Baby", "RAB") {}
}