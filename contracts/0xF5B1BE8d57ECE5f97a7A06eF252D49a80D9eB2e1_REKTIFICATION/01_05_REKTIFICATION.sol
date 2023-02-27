// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GET SAUCED
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    GET REKT + GET SAUCED.    //
//                              //
//    GET SOMETHING.            //
//                              //
//                              //
//////////////////////////////////


contract REKTIFICATION is ERC721Creator {
    constructor() ERC721Creator("GET SAUCED", "REKTIFICATION") {}
}