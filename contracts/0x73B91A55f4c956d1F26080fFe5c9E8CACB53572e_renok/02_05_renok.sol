// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: renok
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//                                            //
//                                            //
//                                  __        //
//    _______   ____   ____   ____ |  | __    //
//    \_  __ \_/ __ \ /    \ /  _ \|  |/ /    //
//     |  | \/\  ___/|   |  (  <_> )    <     //
//     |__|    \___  >___|  /\____/|__|_ \    //
//                 \/     \/            \/    //
//                                            //
//                                            //
//                                            //
//                                            //
////////////////////////////////////////////////


contract renok is ERC721Creator {
    constructor() ERC721Creator("renok", "renok") {}
}