// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Red Rabbit
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////
//                                                                        //
//                                                                        //
//    The strange situations of the red masked rabbit and his friends.    //
//                                                                        //
//                                                                        //
////////////////////////////////////////////////////////////////////////////


contract RR is ERC721Creator {
    constructor() ERC721Creator("Red Rabbit", "RR") {}
}