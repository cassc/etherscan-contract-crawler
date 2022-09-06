// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ConFirMerge
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                                                                            //
//    52 49 47 48 54 45 4F 55 53 4E 45 53 53  49 53  54 48 45  4B 45 59       //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


contract CFM is ERC721Creator {
    constructor() ERC721Creator("ConFirMerge", "CFM") {}
}