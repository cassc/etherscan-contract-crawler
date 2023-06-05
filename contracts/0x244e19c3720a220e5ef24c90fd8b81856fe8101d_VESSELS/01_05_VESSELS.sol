// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Vessels
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                                                 //
//                                     |           //
//     \ \   /  _ \   __|   __|   _ \  |   __|     //
//      \ \ /   __/ \__ \ \__ \   __/  | \__ \     //
//       \_/  \___| ____/ ____/ \___| _| ____/     //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract VESSELS is ERC721Creator {
    constructor() ERC721Creator("Vessels", "VESSELS") {}
}