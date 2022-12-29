// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Will Takeover Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//                                                    //
//     __      _____________________      _____       //
//    /  \    /  \__    ___/\_____  \    /  _  \      //
//    \   \/\/   / |    |    /   |   \  /  /_\  \     //
//     \        /  |    |   /    |    \/    |    \    //
//      \__/\  /   |____|   \_______  /\____|__  /    //
//           \/                     \/         \/     //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract WTOA is ERC721Creator {
    constructor() ERC721Creator("Will Takeover Art", "WTOA") {}
}