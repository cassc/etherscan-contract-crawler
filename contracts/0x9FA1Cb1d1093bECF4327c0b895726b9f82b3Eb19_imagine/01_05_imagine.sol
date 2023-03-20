// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: /imagine
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                                   //
//        ___                       _                //
//       / (_)_ __ ___   __ _  __ _(_)_ __   ___     //
//      / /| | '_ ` _ \ / _` |/ _` | | '_ \ / _ \    //
//     / / | | | | | | | (_| | (_| | | | | |  __/    //
//    /_/  |_|_| |_| |_|\__,_|\__, |_|_| |_|\___|    //
//                            |___/                  //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract imagine is ERC721Creator {
    constructor() ERC721Creator("/imagine", "imagine") {}
}