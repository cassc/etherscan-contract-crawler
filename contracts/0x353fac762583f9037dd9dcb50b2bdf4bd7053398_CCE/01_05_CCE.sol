// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cexaline Collector Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//                                         //
//       _|_|_|     _|_|_|   _|_|_|_|      //
//     _|         _|         _|            //
//     _|         _|         _|_|_|        //
//     _|         _|         _|            //
//       _|_|_|     _|_|_|   _|_|_|_|      //
//                                         //
//                                         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract CCE is ERC721Creator {
    constructor() ERC721Creator("Cexaline Collector Editions", "CCE") {}
}