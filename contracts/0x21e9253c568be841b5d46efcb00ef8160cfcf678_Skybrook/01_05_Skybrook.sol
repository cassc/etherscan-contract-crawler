// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Skybrook
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    Skybrook    //
//                //
//                //
////////////////////


contract Skybrook is ERC721Creator {
    constructor() ERC721Creator("Skybrook", "Skybrook") {}
}