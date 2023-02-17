// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Oggoland
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


contract ByOggo is ERC721Creator {
    constructor() ERC721Creator("Oggoland", "ByOggo") {}
}