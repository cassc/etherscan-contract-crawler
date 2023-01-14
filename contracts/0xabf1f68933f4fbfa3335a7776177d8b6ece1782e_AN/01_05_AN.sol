// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ASYA NUR
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//                              //
//             ___    _   __    //
//       _  __/   |  / | / /    //
//      | |/_/ /| | /  |/ /     //
//     _>  </ ___ |/ /|  /      //
//    /_/|_/_/  |_/_/ |_/       //
//                              //
//                              //
//                              //
//                              //
//////////////////////////////////


contract AN is ERC721Creator {
    constructor() ERC721Creator("ASYA NUR", "AN") {}
}