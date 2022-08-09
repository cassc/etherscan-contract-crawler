// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: underscore_1
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//      _    _  _______   ______      //
//     | |  | |/ ____\ \ / / __ \     //
//     | |  | | (___  \ V / |  | |    //
//     | |  | |\___ \  > <| |  | |    //
//     | |__| |____) |/ . \ |__| |    //
//      \____/|_____//_/ \_\____/     //
//                                    //
//                                    //
//                                    //
////////////////////////////////////////


contract USXO1 is ERC721Creator {
    constructor() ERC721Creator("underscore_1", "USXO1") {}
}