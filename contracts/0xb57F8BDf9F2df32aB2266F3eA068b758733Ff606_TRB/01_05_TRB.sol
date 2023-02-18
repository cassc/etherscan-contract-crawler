// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rebirth
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                    //
//                                                                                                                    //
//    I am a unique digital artist, my forte is abstract arts and I'm currently exploring digital traditional arts    //
//                                                                                                                    //
//                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TRB is ERC721Creator {
    constructor() ERC721Creator("Rebirth", "TRB") {}
}