// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 100daysNFTchallenge
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    OOOOOO0OOOOOO0OOOOOO0OOOOOO0OOOOOO0OOOOOO0OOOOOO0OOOOOO0OOOOOO0OOOOOO0OOOOOO0OOOOOO0OOOOOO0OOOOOO0OO    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NC100 is ERC721Creator {
    constructor() ERC721Creator("100daysNFTchallenge", "NC100") {}
}