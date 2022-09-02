// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hues Of Gigi
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//      _    _  ____   _____     //
//     | |  | |/ __ \ / ____|    //
//     | |__| | |  | | |  __     //
//     |  __  | |  | | | |_ |    //
//     | |  | | |__| | |__| |    //
//     |_|  |_|\____/ \_____|    //
//                               //
//                               //
//                               //
//                               //
///////////////////////////////////


contract HOG is ERC721Creator {
    constructor() ERC721Creator("Hues Of Gigi", "HOG") {}
}