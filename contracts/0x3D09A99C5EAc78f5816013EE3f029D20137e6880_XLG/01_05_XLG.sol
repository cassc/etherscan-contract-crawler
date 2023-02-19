// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: XLegion
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//       _  __ __               _               //
//      | |/ // /   ___  ____ _(_)___  ____     //
//      |   // /   / _ \/ __ `/ / __ \/ __ \    //
//     /   |/ /___/  __/ /_/ / / /_/ / / / /    //
//    /_/|_/_____/\___/\__, /_/\____/_/ /_/     //
//                    /____/                    //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract XLG is ERC721Creator {
    constructor() ERC721Creator("XLegion", "XLG") {}
}