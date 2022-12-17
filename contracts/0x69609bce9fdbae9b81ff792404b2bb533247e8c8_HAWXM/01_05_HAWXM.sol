// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Have a wonderful Christmas
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                          //
//                                                                                                                          //
//      _   _   ______   _  __   ____    ____     ____   __   __                                                            //
//     | \ | | |  ____| | |/ /  / __ \  |  _ \   / __ \  \ \ / /                                                            //
//     |  \| | | |__    | ' /  | |  | | | |_) | | |  | |  \ V /                                                             //
//     | . ` | |  __|   |  <   | |  | | |  _ <  | |  | |   > <                                                              //
//     | |\  | | |____  | . \  | |__| | | |_) | | |__| |  / . \                                                             //
//     |_| \_| |______| |_|\_\  \____/  |____/   \____/  /_/ \_\                                                            //
//    Merry Christmas! May your happiness be large and your bills be small                                                  //
//                                                                                                                          //
//                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HAWXM is ERC1155Creator {
    constructor() ERC1155Creator("Have a wonderful Christmas", "HAWXM") {}
}