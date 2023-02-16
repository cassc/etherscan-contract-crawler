// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sepidart
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//                                              //
//                         .__    .___          //
//      ______ ____ ______ |__| __| _/____      //
//     /  ___// __ \\____ \|  |/ __ |/ __ \     //
//     \___ \\  ___/|  |_> >  / /_/ \  ___/     //
//    /____  >\___  >   __/|__\____ |\___  >    //
//         \/     \/|__|           \/    \/     //
//                                              //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract S8 is ERC721Creator {
    constructor() ERC721Creator("Sepidart", "S8") {}
}