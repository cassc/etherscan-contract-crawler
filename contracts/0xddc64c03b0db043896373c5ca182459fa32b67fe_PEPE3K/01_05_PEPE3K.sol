// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: THE PEPES OF PRODUCTION
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//          ____                                      //
//         /___/\_                                    //
//        _\   \/_/\__                                //
//      __\       \/_/\                               //
//      \   __    __ \ \                              //
//     __\  \_\   \_\ \ \   __                        //
//    /_/\\   __   __  \ \_/_/\                       //
//    \_\/_\__\/\__\/\__\/_\_\/                       //
//       \_\/_/\       /_\_\/                         //
//          \_\/       \_\/                           //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract PEPE3K is ERC1155Creator {
    constructor() ERC1155Creator("THE PEPES OF PRODUCTION", "PEPE3K") {}
}