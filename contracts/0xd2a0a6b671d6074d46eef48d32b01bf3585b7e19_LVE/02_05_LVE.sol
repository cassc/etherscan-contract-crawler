// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Levee
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//                                                  //
//      _____ _  _ ___   _    _____   _____ ___     //
//     |_   _| || | __| | |  | __\ \ / / __| __|    //
//       | | | __ | _|  | |__| _| \ V /| _|| _|     //
//       |_| |_||_|___| |____|___| \_/ |___|___|    //
//                                                  //
//                                                  //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract LVE is ERC721Creator {
    constructor() ERC721Creator("The Levee", "LVE") {}
}