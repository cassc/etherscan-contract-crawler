// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Utopia
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    //UTPCPT//    //
//                  //
//                  //
//////////////////////


contract UTPCPT is ERC721Creator {
    constructor() ERC721Creator("Utopia", "UTPCPT") {}
}