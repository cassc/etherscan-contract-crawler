// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: played per game and the
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                         //
//                                                                                                                         //
//    It was a terrible sight.                                                                                             //
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
//    But Duffy is already a very good player among ordinary people.                                                       //
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
//    For all of Marquette, out of tens of thousands of students, not more than 20 are better than Duffy at basketball.    //
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
//    And that's including the Marquette University players.                                                               //
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
//                                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PPAT is ERC721Creator {
    constructor() ERC721Creator("played per game and the", "PPAT") {}
}