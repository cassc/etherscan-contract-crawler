// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Karisma's Polaroids
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//    I don't have time for this ascii mark thing     //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract KSP is ERC721Creator {
    constructor() ERC721Creator("Karisma's Polaroids", "KSP") {}
}