// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Smog
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//      _________   _____   ________    ________     //
//     /   _____/  /     \  \_____  \  /  _____/     //
//     \_____  \  /  \ /  \  /   |   \/   \  ___     //
//     /        \/    Y    \/    |    \    \_\  \    //
//    /_______  /\____|__  /\_______  /\______  /    //
//            \/         \/         \/        \/     //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract SMG is ERC1155Creator {
    constructor() ERC1155Creator("Smog", "SMG") {}
}