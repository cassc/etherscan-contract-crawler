// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Krait Stamp Cards
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    *-Krait Official Stamp Cards-*    //
//     For Holders and Bidders Only     //
//               KR-SC                  //
//                                      //
//                                      //
//////////////////////////////////////////


contract KRSC is ERC721Creator {
    constructor() ERC721Creator("Krait Stamp Cards", "KRSC") {}
}