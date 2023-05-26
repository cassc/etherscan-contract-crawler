// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DARK TURBO Burn Victims
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//    ________ _____________________ ____   ____     //
//    \______ \\__    ___/\______   \\   \ /   /     //
//     |    |  \ |    |    |    |  _/ \   Y   /      //
//     |    `   \|    |    |    |   \  \     /       //
//    /_______  /|____|    |______  /   \___/        //
//            \/                  \/                 //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract DTBV is ERC1155Creator {
    constructor() ERC1155Creator("DARK TURBO Burn Victims", "DTBV") {}
}