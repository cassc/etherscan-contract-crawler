// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Glitchy Illustration
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//      ________.__  .__  __         .__               //
//     /  _____/|  | |__|/  |_  ____ |  |__ ___.__.    //
//    /   \  ___|  | |  \   __\/ ___\|  |  <   |  |    //
//    \    \_\  \  |_|  ||  | \  \___|   Y  \___  |    //
//     \______  /____/__||__|  \___  >___|  / ____|    //
//            \/                   \/     \/\/         //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract Glitchy is ERC721Creator {
    constructor() ERC721Creator("Glitchy Illustration", "Glitchy") {}
}