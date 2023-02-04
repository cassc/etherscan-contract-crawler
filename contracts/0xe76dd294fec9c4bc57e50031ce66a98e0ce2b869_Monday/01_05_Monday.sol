// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Monday
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//    xxxxxx,,,,,,,,,,,,,,,,,,-----------------TMDAO---------------------,,,,,,,,,,,,,,,xxxxxxxx    //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract Monday is ERC721Creator {
    constructor() ERC721Creator("Monday", "Monday") {}
}