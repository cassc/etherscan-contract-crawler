// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LORS editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//                                     //
//                                     //
//      _      ____  _____   _____     //
//     | |    / __ \|  __ \ / ____|    //
//     | |   | |  | | |__) | (___      //
//     | |   | |  | |  _  / \___ \     //
//     | |___| |__| | | \ \ ____) |    //
//     |______\____/|_|  \_\_____/     //
//                                     //
//                                     //
//                                     //
//                                     //
//                                     //
//                                     //
/////////////////////////////////////////


contract LORS is ERC721Creator {
    constructor() ERC721Creator("LORS editions", "LORS") {}
}