// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MILEGAIN
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//    [̲̅M][̲̅I][̲̅L][̲̅E][̲̅G][̲̅A][̲̅I][̲̅N]    //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract MG is ERC721Creator {
    constructor() ERC721Creator("MILEGAIN", "MG") {}
}