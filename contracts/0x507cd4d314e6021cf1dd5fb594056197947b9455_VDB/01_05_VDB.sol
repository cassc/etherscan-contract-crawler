// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Vahria by Darien Brito
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//    ____   ____      .__          .__            //
//    \   \ /   /____  |  |_________|__|____       //
//     \   Y   /\__  \ |  |  \_  __ \  \__  \      //
//      \     /  / __ \|   Y  \  | \/  |/ __ \_    //
//       \___/  (____  /___|  /__|  |__(____  /    //
//                   \/     \/              \/     //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract VDB is ERC721Creator {
    constructor() ERC721Creator("Vahria by Darien Brito", "VDB") {}
}