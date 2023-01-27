// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: IVAR
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                                        //
//    ._______   _________ __________     //
//    |   \   \ /   /  _  \\______   \    //
//    |   |\   Y   /  /_\  \|       _/    //
//    |   | \     /    |    \    |   \    //
//    |___|  \___/\____|__  /____|_  /    //
//                        \/       \/     //
//                                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract IVAR is ERC721Creator {
    constructor() ERC721Creator("IVAR", "IVAR") {}
}