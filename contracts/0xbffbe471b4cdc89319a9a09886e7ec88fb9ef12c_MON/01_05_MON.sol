// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Meme for Monday
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//                                                      //
//       _____                     .___                 //
//      /     \   ____   ____    __| _/____  ___.__.    //
//     /  \ /  \ /  _ \ /    \  / __ |\__  \<   |  |    //
//    /    Y    (  <_> )   |  \/ /_/ | / __ \\___  |    //
//    \____|__  /\____/|___|  /\____ |(____  / ____|    //
//            \/            \/      \/     \/\/         //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract MON is ERC1155Creator {
    constructor() ERC1155Creator("Meme for Monday", "MON") {}
}