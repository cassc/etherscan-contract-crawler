// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: dollcbt
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    /\_/\      //
//    ( o.o )    //
//     > ^ <     //
//    dollcbt    //
//               //
//               //
///////////////////


contract dollcbt is ERC721Creator {
    constructor() ERC721Creator("dollcbt", "dollcbt") {}
}