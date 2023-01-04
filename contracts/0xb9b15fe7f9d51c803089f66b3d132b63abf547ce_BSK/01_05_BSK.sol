// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: B0B'S SKULL
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    ######    ###   ######      //
//    #     #  #   #  #     #     //
//    #     # #     # #     #     //
//    ######  #     # ######      //
//    #     # #     # #     #     //
//    #     #  #   #  #     #     //
//    ######    ###   ######      //
//     #####  #######  #####      //
//    #     # #     # #     #     //
//    #     # #     # #     #     //
//     #####  #     #  #####      //
//    #     # #     # #     #     //
//    #     # #     # #     #     //
//     #####  #######  #####      //
//                                //
//                                //
////////////////////////////////////


contract BSK is ERC1155Creator {
    constructor() ERC1155Creator("B0B'S SKULL", "BSK") {}
}