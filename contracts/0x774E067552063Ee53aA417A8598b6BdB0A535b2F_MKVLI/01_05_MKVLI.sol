// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MKVLI
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//                                                     //
//       _____   ____  __.____   ____.____    .___     //
//      /     \ |    |/ _|\   \ /   /|    |   |   |    //
//     /  \ /  \|      <   \   Y   / |    |   |   |    //
//    /    Y    \    |  \   \     /  |    |___|   |    //
//    \____|__  /____|__ \   \___/   |_______ \___|    //
//            \/        \/                   \/        //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract MKVLI is ERC721Creator {
    constructor() ERC721Creator("MKVLI", "MKVLI") {}
}