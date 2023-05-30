// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VeeRocks
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//                 1/1 Hand Painted Rocks                 //
//    Closing the gap between physical and digital art    //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract VR is ERC721Creator {
    constructor() ERC721Creator("VeeRocks", "VR") {}
}