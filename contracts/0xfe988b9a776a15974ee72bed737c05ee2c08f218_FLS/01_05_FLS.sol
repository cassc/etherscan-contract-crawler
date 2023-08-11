// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fame Lady Squad Art Drops
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//                                      //
//     _______  __          _______.    //
//    |   ____||  |        /       |    //
//    |  |__   |  |       |   (----`    //
//    |   __|  |  |        \   \        //
//    |  |     |  `----.----)   |       //
//    |__|     |_______|_______/        //
//                                      //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract FLS is ERC1155Creator {
    constructor() ERC1155Creator("Fame Lady Squad Art Drops", "FLS") {}
}