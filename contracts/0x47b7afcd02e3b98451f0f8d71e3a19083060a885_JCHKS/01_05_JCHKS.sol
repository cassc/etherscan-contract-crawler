// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Juicechecks
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//    This juicebox may or may not be notable.    //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract JCHKS is ERC721Creator {
    constructor() ERC721Creator("Juicechecks", "JCHKS") {}
}