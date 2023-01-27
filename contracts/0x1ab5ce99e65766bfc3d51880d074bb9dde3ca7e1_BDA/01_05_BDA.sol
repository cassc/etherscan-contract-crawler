// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dreamers and Adventurers
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//                                                  //
//      ____        _    _   ____        _    _     //
//     | __ )  ___ | | _(_) | __ )  ___ | | _(_)    //
//     |  _ \ / _ \| |/ / | |  _ \ / _ \| |/ / |    //
//     | |_) | (_) |   <| | | |_) | (_) |   <| |    //
//     |____/ \___/|_|\_\_| |____/ \___/|_|\_\_|    //
//                                                  //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract BDA is ERC721Creator {
    constructor() ERC721Creator("Dreamers and Adventurers", "BDA") {}
}