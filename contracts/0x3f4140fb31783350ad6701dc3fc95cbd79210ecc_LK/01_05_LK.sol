// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lost Kingdoms
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//    These water mirrors reflect everything that exists. From good to evil, from order to chaos    //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract LK is ERC721Creator {
    constructor() ERC721Creator("Lost Kingdoms", "LK") {}
}