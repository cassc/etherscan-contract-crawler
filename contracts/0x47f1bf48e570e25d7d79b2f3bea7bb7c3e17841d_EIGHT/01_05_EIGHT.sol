// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Radiant Eight A.I.
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    ________    ________          //
//    \  ____ \   \  ____ \         //
//     \ \___\ \   \ \___\ \        //
//      \   ___ |_  \__   __\       //
//       \  \  \  \  \  ____ \      //
//        \  \  \  \  \ \___\ \     //
//         \__\  \__\  \_______\    //
//                                  //
//                                  //
//////////////////////////////////////


contract EIGHT is ERC721Creator {
    constructor() ERC721Creator("Radiant Eight A.I.", "EIGHT") {}
}