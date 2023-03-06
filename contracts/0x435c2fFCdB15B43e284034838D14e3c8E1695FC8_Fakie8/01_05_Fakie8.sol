// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FAKIE8
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//        ______      __   _                      //
//       / ____/___ _/ /__(_)__                   //
//      / /_  / __ `/ //_/ / _ \                  //
//     / __/ / /_/ / ,< / /  __/ 8                //
//    /_/    \__,_/_/|_/_/\___/                   //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract Fakie8 is ERC721Creator {
    constructor() ERC721Creator("FAKIE8", "Fakie8") {}
}