// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Balancing act
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//     ____   ____ |__| ____    ____   _____    _____/  |_                                //
//     | __ \\__  \ |  | \__  \  /    \_/ ___\|  |/    \  / ___\  \__  \ _/ ___\   __\    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract SJD is ERC721Creator {
    constructor() ERC721Creator("Balancing act", "SJD") {}
}