// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: META MUSE CLUB
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                                        //
//       _____      _____  _________      //
//      /     \    /     \ \_   ___ \     //
//     /  \ /  \  /  \ /  \/    \  \/     //
//    /    Y    \/    Y    \     \____    //
//    \____|__  /\____|__  /\______  /    //
//            \/         \/        \/     //
//                                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract MMC is ERC721Creator {
    constructor() ERC721Creator("META MUSE CLUB", "MMC") {}
}