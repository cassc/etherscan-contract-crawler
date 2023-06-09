// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: My Square : Access Pass
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//       .----.        //
//       |C>_ |        //
//     __|____|__      //
//    |  ______--|     //
//    `-/.::::.\-'a    //
//     `--------'      //
//                     //
//                     //
/////////////////////////


contract MSAP is ERC721Creator {
    constructor() ERC721Creator("My Square : Access Pass", "MSAP") {}
}