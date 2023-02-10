// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Smile
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//                   .__.__              //
//      ______ _____ |__|  |   ____      //
//     /  ___//     \|  |  | _/ __ \     //
//     \___ \|  Y Y  \  |  |_\  ___/     //
//    /____  >__|_|  /__|____/\___  >    //
//         \/      \/             \/     //
//                                       //
//                                       //
///////////////////////////////////////////


contract smileanon is ERC721Creator {
    constructor() ERC721Creator("Smile", "smileanon") {}
}