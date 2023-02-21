// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Capepeccino
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//       _________    ____  __________     //
//      / ____/   |  / __ \/ ____/ __ \    //
//     / /   / /| | / /_/ / __/ / /_/ /    //
//    / /___/ ___ |/ ____/ /___/ ____/     //
//    \____/_/  |_/_/   /_____/_/          //
//                                         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract CAPEP is ERC721Creator {
    constructor() ERC721Creator("Capepeccino", "CAPEP") {}
}