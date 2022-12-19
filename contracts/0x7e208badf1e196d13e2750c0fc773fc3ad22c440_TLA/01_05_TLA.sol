// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Balloon Girl
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//                                       //
//    ___________.____       _____       //
//    \__    ___/|    |     /  _  \      //
//      |    |   |    |    /  /_\  \     //
//      |    |   |    |___/    |    \    //
//      |____|   |_______ \____|__  /    //
//                       \/       \/     //
//                                       //
//                                       //
//                                       //
///////////////////////////////////////////


contract TLA is ERC721Creator {
    constructor() ERC721Creator("Balloon Girl", "TLA") {}
}