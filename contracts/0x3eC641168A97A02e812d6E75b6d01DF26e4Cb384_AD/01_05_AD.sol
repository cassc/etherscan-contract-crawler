// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: American Dream
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//        ____        __  __                 //
//       / __ \____  / /_/ /_  ___  _____    //
//      / /_/ / __ \/ __/ __ \/ _ \/ ___/    //
//     / _, _/ /_/ / /_/ / / /  __/ /        //
//    /_/ |_|\____/\__/_/ /_/\___/_/         //
//                                           //
//                                           //
//                                           //
///////////////////////////////////////////////


contract AD is ERC721Creator {
    constructor() ERC721Creator("American Dream", "AD") {}
}