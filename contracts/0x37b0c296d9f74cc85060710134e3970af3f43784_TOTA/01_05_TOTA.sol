// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TreasuryOfTrueArt
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    // Treasury of true art \\    //
//                                  //
//                                  //
//                                  //
//////////////////////////////////////


contract TOTA is ERC721Creator {
    constructor() ERC721Creator("TreasuryOfTrueArt", "TOTA") {}
}