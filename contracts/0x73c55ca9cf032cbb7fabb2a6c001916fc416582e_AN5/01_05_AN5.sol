// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: alexntesting
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//                                          //
//           .__                            //
//    _____  |  |   ____ ___  ___ ____      //
//    \__  \ |  | _/ __ \\  \/  //    \     //
//     / __ \|  |_\  ___/ >    <|   |  \    //
//    (____  /____/\___  >__/\_ \___|  /    //
//         \/          \/      \/    \/     //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract AN5 is ERC721Creator {
    constructor() ERC721Creator("alexntesting", "AN5") {}
}