// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: STiLL LiFE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    Vaughn Taormina Still Life    //
//                                  //
//                                  //
//////////////////////////////////////


contract VTC is ERC721Creator {
    constructor() ERC721Creator("STiLL LiFE", "VTC") {}
}