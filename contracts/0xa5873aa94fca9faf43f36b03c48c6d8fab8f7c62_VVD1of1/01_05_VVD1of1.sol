// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VVD 1/1s
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////
//                                                                     //
//                                                                     //
//                                                                     //
//    ____   ________   ____________     ____      /\  ____            //
//    \   \ /   /\   \ /   /\______ \   /_   |    / / /_   | ______    //
//     \   Y   /  \   Y   /  |    |  \   |   |   / /   |   |/  ___/    //
//      \     /    \     /   |    `   \  |   |  / /    |   |\___ \     //
//       \___/      \___/   /_______  /  |___| / /     |___/____  >    //
//                                  \/         \/               \/     //
//                                                                     //
//                                                                     //
//                                                                     //
/////////////////////////////////////////////////////////////////////////


contract VVD1of1 is ERC721Creator {
    constructor() ERC721Creator("VVD 1/1s", "VVD1of1") {}
}