// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Alexes Premiere Collection
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    Alexes Premiere Collection    //
//                                  //
//                                  //
//////////////////////////////////////


contract APC2022 is ERC721Creator {
    constructor() ERC721Creator("Alexes Premiere Collection", "APC2022") {}
}