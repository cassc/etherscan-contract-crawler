// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: African Carbon Dao
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//       _____  _________   ________________        //
//      /  _  \ \_   ___ \ /  _____/\______ \       //
//     /  /_\  \/    \  \//   __  \  |    |  \      //
//    /    |    \     \___\  |__\  \ |    `   \     //
//    \____|__  /\______  /\_____  //_______  /     //
//            \/        \/       \/         \/      //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract AC6D is ERC721Creator {
    constructor() ERC721Creator("African Carbon Dao", "AC6D") {}
}