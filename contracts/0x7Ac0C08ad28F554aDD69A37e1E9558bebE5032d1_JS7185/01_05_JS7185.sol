// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Any color you like
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//                                                           //
//         _        _               ___ _           _        //
//      _ | |___ __| |_ _  _ __ _  / __(_)_ _  __ _| |_      //
//     | || / _ (_-< ' \ || / _` | \__ \ | ' \/ _` | ' \     //
//      \__/\___/__/_||_\_,_\__,_| |___/_|_||_\__, |_||_|    //
//                                            |___/          //
//                                                           //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract JS7185 is ERC721Creator {
    constructor() ERC721Creator("Any color you like", "JS7185") {}
}