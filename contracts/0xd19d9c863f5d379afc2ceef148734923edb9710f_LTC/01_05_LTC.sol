// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LuckyTheCat
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    lucky the cat so desperate    //
//                                  //
//                                  //
//////////////////////////////////////


contract LTC is ERC721Creator {
    constructor() ERC721Creator("LuckyTheCat", "LTC") {}
}