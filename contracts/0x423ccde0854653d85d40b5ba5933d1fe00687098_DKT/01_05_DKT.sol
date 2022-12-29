// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dukt
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//    Why be fukt when you can be dukt    //
//                                        //
//                                        //
////////////////////////////////////////////


contract DKT is ERC721Creator {
    constructor() ERC721Creator("Dukt", "DKT") {}
}