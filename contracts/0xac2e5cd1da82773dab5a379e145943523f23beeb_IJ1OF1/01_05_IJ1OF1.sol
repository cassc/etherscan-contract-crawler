// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: IJ 1/1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//         IJ 1/1                            //
//                                           //
//         twitter.com/ijcollects            //
//                                           //
//                                           //
///////////////////////////////////////////////


contract IJ1OF1 is ERC721Creator {
    constructor() ERC721Creator("IJ 1/1", "IJ1OF1") {}
}