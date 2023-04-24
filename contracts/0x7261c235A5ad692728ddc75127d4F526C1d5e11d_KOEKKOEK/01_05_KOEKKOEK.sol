// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Koekkoek
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    [ˈkʊkʊk]    //
//                //
//                //
////////////////////


contract KOEKKOEK is ERC721Creator {
    constructor() ERC721Creator("Koekkoek", "KOEKKOEK") {}
}