// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: new_uruk
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                                   //
//                                         | |       //
//     _ __   _____      ___   _ _ __ _   _| | __    //
//    | '_ \ / _ \ \ /\ / / | | | '__| | | | |/ /    //
//    | | | |  __/\ V  V /| |_| | |  | |_| |   <     //
//    |_| |_|\___| \_/\_/  \__,_|_|   \__,_|_|\_\    //
//                    ______                         //
//                   |______|                        //
//                                                   //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract URUK is ERC721Creator {
    constructor() ERC721Creator("new_uruk", "URUK") {}
}