// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Takeover Collabs
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                                                 //
//    ____________   _________________________     //
//    \_____  \   \ /   /\_   _____/\______   \    //
//     /   |   \   Y   /  |    __)_  |       _/    //
//    /    |    \     /   |        \ |    |   \    //
//    \_______  /\___/   /_______  / |____|_  /    //
//            \/                 \/         \/     //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract OVER is ERC1155Creator {
    constructor() ERC1155Creator("Takeover Collabs", "OVER") {}
}