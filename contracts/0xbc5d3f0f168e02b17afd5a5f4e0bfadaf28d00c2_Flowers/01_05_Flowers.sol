// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Flowers
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////
//                                                                        //
//                                                                        //
//    The momentary glimmer of fashion models as their beauty unfolds.    //
//                                                                        //
//                                                                        //
////////////////////////////////////////////////////////////////////////////


contract Flowers is ERC721Creator {
    constructor() ERC721Creator("Flowers", "Flowers") {}
}