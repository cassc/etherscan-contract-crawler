// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Frensss
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//                                                //
//    ___________                                 //
//    \_   _____/______   ____   ____   ______    //
//     |    __) \_  __ \_/ __ \ /    \ /  ___/    //
//     |     \   |  | \/\  ___/|   |  \\___ \     //
//     \___  /   |__|    \___  >___|  /____  >    //
//         \/                \/     \/     \/     //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract Frens is ERC721Creator {
    constructor() ERC721Creator("Frensss", "Frens") {}
}