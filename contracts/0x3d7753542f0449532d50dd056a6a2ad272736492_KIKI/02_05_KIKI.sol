// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KIKI CLASS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    Kiki Class    //
//                  //
//                  //
//////////////////////


contract KIKI is ERC721Creator {
    constructor() ERC721Creator("KIKI CLASS", "KIKI") {}
}