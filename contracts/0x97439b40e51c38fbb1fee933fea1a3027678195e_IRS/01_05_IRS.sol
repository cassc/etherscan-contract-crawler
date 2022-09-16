// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Immortal Rune Shards
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////
//                                                                //
//                                                                //
//    Rune Shards for the 1/1 SkullKids: Immortal Collection.     //
//    Collect them to get a Rune!                                 //
//    www.badfroot.com                                            //
//                                                                //
//                                                                //
////////////////////////////////////////////////////////////////////


contract IRS is ERC721Creator {
    constructor() ERC721Creator("Immortal Rune Shards", "IRS") {}
}