// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Out Of This World
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//    \_____  \  /  _____/ /  _____/ \_____  \      //
//     /   |   \/   \  ___/   \  ___  /   |   \     //
//    /    |    \    \_\  \    \_\  \/    |    \    //
//    \_______  /\______  /\______  /\_______  /    //
//            \/        \/        \/         \/     //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract ByOGGO is ERC721Creator {
    constructor() ERC721Creator("Out Of This World", "ByOGGO") {}
}