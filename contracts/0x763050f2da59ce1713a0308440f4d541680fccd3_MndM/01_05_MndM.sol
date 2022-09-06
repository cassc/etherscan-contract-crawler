// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MindMeld
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//    One human, one machine, one output.     //
//                                            //
//                                            //
////////////////////////////////////////////////


contract MndM is ERC721Creator {
    constructor() ERC721Creator("MindMeld", "MndM") {}
}