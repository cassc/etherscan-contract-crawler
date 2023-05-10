// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Patrons DAO
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//    50 61 74 72 6F 6E 73 20 44 41 4F    //
//                                        //
//                                        //
////////////////////////////////////////////


contract PATRONS is ERC721Creator {
    constructor() ERC721Creator("Patrons DAO", "PATRONS") {}
}