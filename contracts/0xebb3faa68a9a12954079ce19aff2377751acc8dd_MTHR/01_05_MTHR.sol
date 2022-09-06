// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mother
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                                   //
//       _____          __  .__                      //
//      /     \   _____/  |_|  |__   ___________     //
//     /  \ /  \ /  _ \   __\  |  \_/ __ \_  __ \    //
//    /    Y    (  <_> )  | |   Y  \  ___/|  | \/    //
//    \____|__  /\____/|__| |___|  /\___  >__|       //
//            \/                 \/     \/           //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract MTHR is ERC721Creator {
    constructor() ERC721Creator("Mother", "MTHR") {}
}