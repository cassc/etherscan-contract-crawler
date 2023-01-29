// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ndb pass
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//        _   ______  ____     //
//       / | / / __ \/ __ )    //
//      /  |/ / / / / __  |    //
//     / /|  / /_/ / /_/ /     //
//    /_/ |_/_____/_____/      //
//                             //
//                             //
//                             //
/////////////////////////////////


contract NDB is ERC721Creator {
    constructor() ERC721Creator("ndb pass", "NDB") {}
}