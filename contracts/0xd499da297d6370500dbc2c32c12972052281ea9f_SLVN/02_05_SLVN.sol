// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: slvnart
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                                   //
//           .__                            __       //
//      _____|  |___  ______ _____ ________/  |_     //
//     /  ___/  |\  \/ /    \\__  \\_  __ \   __\    //
//     \___ \|  |_\   /   |  \/ __ \|  | \/|  |      //
//    /____  >____/\_/|___|  (____  /__|   |__|      //
//         \/              \/     \/                 //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract SLVN is ERC721Creator {
    constructor() ERC721Creator("slvnart", "SLVN") {}
}