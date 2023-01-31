// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Masters of the Unknown Sport
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//    The Masters of the Unknown Sport    //
//                                        //
//                                        //
////////////////////////////////////////////


contract MASTERS is ERC721Creator {
    constructor() ERC721Creator("The Masters of the Unknown Sport", "MASTERS") {}
}