// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Make ART to me!
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//       _____ _____________________    //
//      /  _  \\______   \__    ___/    //
//     /  /_\  \|       _/ |    |       //
//    /    |    \    |   \ |    |       //
//    \____|__  /____|_  / |____|       //
//            \/       \/               //
//                                      //
//                                      //
//////////////////////////////////////////


contract ART is ERC721Creator {
    constructor() ERC721Creator("Make ART to me!", "ART") {}
}