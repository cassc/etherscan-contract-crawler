// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bbleiztz
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                               //
//                                                                                                               //
//    Seize the fakes, the memes, the memes of the fakes, the fakes of the fakes of the memes, of... OVERFAKE    //
//                                                                                                               //
//                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ofake is ERC721Creator {
    constructor() ERC721Creator("Bbleiztz", "ofake") {}
}