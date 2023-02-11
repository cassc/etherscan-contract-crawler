// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ordinal 0mens
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                                        //
//    _______                             //
//    \   _  \   _____   ____   ____      //
//    /  /_\  \ /     \_/ __ \ /    \     //
//    \  \_/   \  Y Y  \  ___/|   |  \    //
//     \_____  /__|_|  /\___  >___|  /    //
//           \/      \/     \/     \/     //
//                                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract omens is ERC721Creator {
    constructor() ERC721Creator("Ordinal 0mens", "omens") {}
}