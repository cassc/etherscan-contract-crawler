// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Chroma_Code_Limited
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//                 \  /              //
//                  \/               //
//        .===============.          //
//        | .-----------. |          //
//        | |           | |          //
//        | |           | |          //
//        | |           | |   __     //
//        | '-----------'o|  |o.|    //
//        |===============|  |::|    //
//        |  CHROMA CODE  |  |::|    //
//        '==============='  '--'    //
//                                   //
//                                   //
///////////////////////////////////////


contract CODEL is ERC1155Creator {
    constructor() ERC1155Creator("Chroma_Code_Limited", "CODEL") {}
}