// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JOÃO SALAZAR 1/1s
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    js 1/1 :))    //
//                  //
//                  //
//////////////////////


contract JS1 is ERC721Creator {
    constructor() ERC721Creator(unicode"JOÃO SALAZAR 1/1s", "JS1") {}
}