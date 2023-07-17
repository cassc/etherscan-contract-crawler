// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Checks Meta - Pepe Edition
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//                                     //
//                                     //
//    ______   ____ ______   ____      //
//    \____ \_/ __ \\____ \_/ __ \     //
//    |  |_> >  ___/|  |_> >  ___/     //
//    |   __/ \___  >   __/ \___  >    //
//    |__|        \/|__|        \/     //
//                                     //
//                                     //
//                                     //
/////////////////////////////////////////


contract PEPE is ERC721Creator {
    constructor() ERC721Creator("Checks Meta - Pepe Edition", "PEPE") {}
}