// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TributeToBrokeDay
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    by whatisiana    //
//                     //
//                     //
/////////////////////////


contract TTBD is ERC721Creator {
    constructor() ERC721Creator("TributeToBrokeDay", "TTBD") {}
}