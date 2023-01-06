// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A3Genesis
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//    Genesis collection by Akashi30.     //
//    CCO license.                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract A3G is ERC721Creator {
    constructor() ERC721Creator("A3Genesis", "A3G") {}
}