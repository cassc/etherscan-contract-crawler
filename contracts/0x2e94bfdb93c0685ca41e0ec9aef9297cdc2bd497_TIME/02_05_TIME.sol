// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TIMELESS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//                                                //
//                                                //
//      _____ ___ __  __ ___ _    ___ ___ ___     //
//     |_   _|_ _|  \/  | __| |  | __/ __/ __|    //
//       | |  | || |\/| | _|| |__| _|\__ \__ \    //
//       |_| |___|_|  |_|___|____|___|___/___/    //
//                                                //
//                                                //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract TIME is ERC721Creator {
    constructor() ERC721Creator("TIMELESS", "TIME") {}
}