// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MetaTalism Mini Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//     __  __ __  __ ____      //
//    |  \/  |  \/  |___ \     //
//    | |\/| | |\/| |   | |    //
//    | |  | | |  | |___| |    //
//    |_|  |_|_|  |_|____/     //
//                             //
//                             //
//                             //
/////////////////////////////////


contract MMC is ERC721Creator {
    constructor() ERC721Creator("MetaTalism Mini Collection", "MMC") {}
}