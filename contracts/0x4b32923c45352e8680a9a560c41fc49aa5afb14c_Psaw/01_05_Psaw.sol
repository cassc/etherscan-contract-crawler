// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PsawMasker
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    PsawMasker    //
//                  //
//                  //
//////////////////////


contract Psaw is ERC721Creator {
    constructor() ERC721Creator("PsawMasker", "Psaw") {}
}