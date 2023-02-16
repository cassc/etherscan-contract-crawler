// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BLISSFUL NIGHT
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//                                      //
//     ___  _ _  ___  ___  _ _  ___     //
//    | . >| | || . \| . \| | || . |    //
//    | . \| ' || | || | ||   ||   |    //
//    |___/`___'|___/|___/|_|_||_|_|    //
//                                      //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract buddha is ERC721Creator {
    constructor() ERC721Creator("BLISSFUL NIGHT", "buddha") {}
}