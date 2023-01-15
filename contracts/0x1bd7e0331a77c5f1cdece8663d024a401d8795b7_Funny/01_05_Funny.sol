// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FunnyVerse
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//                                            //
//    ___________                             //
//    \_   _____/_ __  ____   ____ ___.__.    //
//     |    __)|  |  \/    \ /    <   |  |    //
//     |     \ |  |  /   |  \   |  \___  |    //
//     \___  / |____/|___|  /___|  / ____|    //
//         \/             \/     \/\/         //
//                                            //
//                                            //
//                                            //
////////////////////////////////////////////////


contract Funny is ERC721Creator {
    constructor() ERC721Creator("FunnyVerse", "Funny") {}
}