// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Return to Beauty
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    Return to Beauty    //
//                        //
//                        //
////////////////////////////


contract REB is ERC721Creator {
    constructor() ERC721Creator("Return to Beauty", "REB") {}
}