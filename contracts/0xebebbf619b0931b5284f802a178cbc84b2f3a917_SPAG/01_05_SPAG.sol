// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Spaghettification
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//                      56 4F 49 44                           //
//    53 70 61 67 68 65 74 74 69 66 69 63 61 74 69 6F 6E      //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract SPAG is ERC721Creator {
    constructor() ERC721Creator("Spaghettification", "SPAG") {}
}