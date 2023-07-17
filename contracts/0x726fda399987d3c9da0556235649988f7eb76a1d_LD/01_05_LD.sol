// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Laundry day
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                                                 //
//    |¯¯¯|__'   )¯¯,¯\ ° |¯¯¯|_|¯¯'|              //
//    |_____'|  /__/'\__\ |\______/|               //
//    |_____'| |__ |/\|__|' \|_____|/‘             //
//    ‘           '                                //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract LD is ERC721Creator {
    constructor() ERC721Creator("Laundry day", "LD") {}
}