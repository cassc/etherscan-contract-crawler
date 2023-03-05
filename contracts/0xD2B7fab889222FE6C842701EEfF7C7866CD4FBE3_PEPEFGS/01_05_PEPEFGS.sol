// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Campepe's Feels Good Soup
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    "It's amazing what soup can do!    //
//    Fill up on the good stuff."        //
//                                       //
//    - Pepe                             //
//                                       //
//                                       //
///////////////////////////////////////////


contract PEPEFGS is ERC721Creator {
    constructor() ERC721Creator("Campepe's Feels Good Soup", "PEPEFGS") {}
}