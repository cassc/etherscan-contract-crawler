// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PixelDrops by Sammy Arriaga
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//    ______________  ___.____     ________       //
//    \______   \   \/  /|    |    \______ \      //
//     |     ___/\     / |    |     |    |  \     //
//     |    |    /     \ |    |___  |    `   \    //
//     |____|   /___/\  \|_______ \/_______  /    //
//                    \_/        \/        \/     //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract PXLDRO is ERC1155Creator {
    constructor() ERC1155Creator("PixelDrops by Sammy Arriaga", "PXLDRO") {}
}