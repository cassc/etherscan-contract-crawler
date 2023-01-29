// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MenaceToSobriety
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//    How do i mint this shit     //
//                                //
//                                //
////////////////////////////////////


contract MTS is ERC721Creator {
    constructor() ERC721Creator("MenaceToSobriety", "MTS") {}
}