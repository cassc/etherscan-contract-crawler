// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Eren ARIK
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    Eren ARIK 1/1    //
//                     //
//                     //
/////////////////////////


contract EA1 is ERC721Creator {
    constructor() ERC721Creator("Eren ARIK", "EA1") {}
}