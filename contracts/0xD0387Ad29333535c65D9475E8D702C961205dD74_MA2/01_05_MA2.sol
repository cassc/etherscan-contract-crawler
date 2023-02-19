// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ma2kenta
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//             __                      //
//      _____ |  | __ ____   ____      //
//     /     \|  |/ // __ \ /    \     //
//    | | YY \ <\ ___/| | | \          //
//    |__|_| /__|_ \\___ >___| /       //
//          \/     \/    \/     \/     //
//                                     //
//                                     //
/////////////////////////////////////////


contract MA2 is ERC721Creator {
    constructor() ERC721Creator("ma2kenta", "MA2") {}
}