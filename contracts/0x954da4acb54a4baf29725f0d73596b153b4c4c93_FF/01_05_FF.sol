// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fantastical Finality
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    Fantastical Finality    //
//                            //
//                            //
////////////////////////////////


contract FF is ERC721Creator {
    constructor() ERC721Creator("Fantastical Finality", "FF") {}
}