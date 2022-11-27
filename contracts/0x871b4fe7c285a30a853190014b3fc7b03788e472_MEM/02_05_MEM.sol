// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tenebrous
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//      |                      |                            //
//       _|   -_)    \    -_)   _ \   _| _ \  |  | (_-<     //
//     \__| \___| _| _| \___| _.__/ _| \___/ \_,_| ___/     //
//                                                          //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract MEM is ERC721Creator {
    constructor() ERC721Creator("Tenebrous", "MEM") {}
}