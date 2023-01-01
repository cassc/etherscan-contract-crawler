// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Vaughn Meadows 1/1s
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//    official contract for 1/1s by vaughn meadows    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract VMDWS is ERC721Creator {
    constructor() ERC721Creator("Vaughn Meadows 1/1s", "VMDWS") {}
}