// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: REMNANTS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                                   //
//      ___ ___ __  __ _  _   _   _  _ _____ ___     //
//     | _ \ __|  \/  | \| | /_\ | \| |_   _/ __|    //
//     |   / _|| |\/| | .` |/ _ \| .` | | | \__ \    //
//     |_|_\___|_|  |_|_|\_/_/ \_\_|\_| |_| |___/    //
//                                                   //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract RMNTS is ERC721Creator {
    constructor() ERC721Creator("REMNANTS", "RMNTS") {}
}