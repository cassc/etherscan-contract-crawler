// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pink Alpaca
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    (◕(‘人‘) ◕)    //
//                  //
//                  //
//////////////////////


contract ALPACA is ERC721Creator {
    constructor() ERC721Creator("Pink Alpaca", "ALPACA") {}
}