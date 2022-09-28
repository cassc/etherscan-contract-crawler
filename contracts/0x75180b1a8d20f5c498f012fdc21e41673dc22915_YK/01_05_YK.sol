// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: yuki
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//                                          //
//    ________________.___.____  __.___     //
//    \__    ___/\__  |   |    |/ _|   |    //
//      |    |    /   |   |      < |   |    //
//      |    |    \____   |    |  \|   |    //
//      |____|    / ______|____|__ \___|    //
//                \/              \/        //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract YK is ERC721Creator {
    constructor() ERC721Creator("yuki", "YK") {}
}