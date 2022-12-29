// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: EDITIONS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//    ------- all the editions -----------    //
//    ------- don't clog the FND ---------    //
//    ------- see what will happen -------    //
//                                            //
//                                            //
//                                            //
////////////////////////////////////////////////


contract EDS is ERC721Creator {
    constructor() ERC721Creator("EDITIONS", "EDS") {}
}