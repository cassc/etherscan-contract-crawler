// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: New world
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    for one priceless moment        //
//    in the whole history of man     //
//    all the people on this earth    //
//    are truly                       //
//    ONE                             //
//                                    //
//                                    //
////////////////////////////////////////


contract NW1 is ERC721Creator {
    constructor() ERC721Creator("New world", "NW1") {}
}