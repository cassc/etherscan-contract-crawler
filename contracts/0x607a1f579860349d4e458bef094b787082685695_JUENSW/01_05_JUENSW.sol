// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Jungle Environment
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//         ____.____ __________    ________.____     ___________    //
//        |    |    |   \      \  /  _____/|    |    \_   _____/    //
//        |    |    |   /   |   \/   \  ___|    |     |    __)_     //
//    /\__|    |    |  /    |    \    \_\  \    |___  |        \    //
//    \________|______/\____|__  /\______  /_______ \/_______  /    //
//                             \/        \/        \/        \/     //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract JUENSW is ERC721Creator {
    constructor() ERC721Creator("Jungle Environment", "JUENSW") {}
}