// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: totem
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//                               //
//                               //
//                               //
//     ___ ___ _ _ _ ___ ___     //
//    |_ -| . | | | | . | . |    //
//    |___|_  |_____|_  |___|    //
//          |_|       |_|        //
//                               //
//                               //
//                               //
///////////////////////////////////


contract totem is ERC721Creator {
    constructor() ERC721Creator("totem", "totem") {}
}