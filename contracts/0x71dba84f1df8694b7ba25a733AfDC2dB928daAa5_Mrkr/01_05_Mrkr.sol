// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Marker
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//      __  __            _                  //
//     |  \/  |          | |                 //
//     | \  / | __ _ _ __| | _____ _ __      //
//     | |\/| |/ _` | '__| |/ / _ \ '__|     //
//     | |  | | (_| | |  |   <  __/ |        //
//     |_|  |_|\__,_|_|  |_|\_\___|_|        //
//                                           //
//                                           //
//                                           //
//                                           //
///////////////////////////////////////////////


contract Mrkr is ERC721Creator {
    constructor() ERC721Creator("Marker", "Mrkr") {}
}