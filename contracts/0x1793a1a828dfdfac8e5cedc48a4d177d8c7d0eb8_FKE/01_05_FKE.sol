// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FAKE GOTHIC
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//                                               //
//    ________________   ____  __.___________    //
//    \_   _____/  _  \ |    |/ _|\_   _____/    //
//     |    __)/  /_\  \|      <   |    __)_     //
//     |     \/    |    \    |  \  |        \    //
//     \___  /\____|__  /____|__ \/_______  /    //
//         \/         \/        \/        \/     //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract FKE is ERC721Creator {
    constructor() ERC721Creator("FAKE GOTHIC", "FKE") {}
}