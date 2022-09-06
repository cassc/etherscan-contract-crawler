// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nansen Chess Club - The Tournament of The Knights
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//     _____ _                     _____ _       _         //
//    /  __ \ |                   /  __ \ |     | |        //
//    | /  \/ |__   ___  ___ ___  | /  \/ |_   _| |__      //
//    | |   | '_ \ / _ \/ __/ __| | |   | | | | | '_ \     //
//    | \__/\ | | |  __/\__ \__ \ | \__/\ | |_| | |_) |    //
//     \____/_| |_|\___||___/___/  \____/_|\__,_|_.__/     //
//                                                         //
//                                                         //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract TTOTK is ERC721Creator {
    constructor() ERC721Creator("Nansen Chess Club - The Tournament of The Knights", "TTOTK") {}
}