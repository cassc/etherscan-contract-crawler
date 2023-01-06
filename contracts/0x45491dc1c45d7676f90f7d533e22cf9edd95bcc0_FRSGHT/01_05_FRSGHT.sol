// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FRSGHTD
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//    Generative art coming soon to http://frsghtd.art/    //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract FRSGHT is ERC721Creator {
    constructor() ERC721Creator("FRSGHTD", "FRSGHT") {}
}