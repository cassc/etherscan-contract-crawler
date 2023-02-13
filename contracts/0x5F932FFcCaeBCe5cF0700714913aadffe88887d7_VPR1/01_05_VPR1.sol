// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Variant Pipe Race
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//     _     ____  ____     //
//    / \ |\/  __\/  __\    //
//    | | //|  \/||  \/|    //
//    | \// |  __/|    /    //
//    \__/  \_/   \_/\_\    //
//                          //
//                          //
//////////////////////////////


contract VPR1 is ERC721Creator {
    constructor() ERC721Creator("Variant Pipe Race", "VPR1") {}
}