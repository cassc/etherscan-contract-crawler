// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Samedi02
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//    ___________________      _____   ________       //
//    \_   _____/\_____  \    /     \  \_____  \      //
//     |    __)   /   |   \  /  \ /  \  /   |   \     //
//     |     \   /    |    \/    Y    \/    |    \    //
//     \___  /   \_______  /\____|__  /\_______  /    //
//         \/            \/         \/         \/     //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract FOMO is ERC1155Creator {
    constructor() ERC1155Creator("Samedi02", "FOMO") {}
}