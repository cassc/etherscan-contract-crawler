// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: For a Drop of Life
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//     _______    _________ ________________     //
//     \      \  /   _____//  _____/   __   \    //
//     /   |   \ \_____  \/   __  \\____    /    //
//    /    |    \/        \  |__\  \  /    /     //
//    \____|__  /_______  /\_____  / /____/      //
//            \/        \/       \/              //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract NS69 is ERC1155Creator {
    constructor() ERC1155Creator("For a Drop of Life", "NS69") {}
}