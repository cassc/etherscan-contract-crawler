// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: YOKAI
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    妖怪 , yōkai                      //
//    In the most psychedelic way.    //
//                                    //
//                                    //
//                                    //
////////////////////////////////////////


contract owl is ERC721Creator {
    constructor() ERC721Creator("YOKAI", "owl") {}
}