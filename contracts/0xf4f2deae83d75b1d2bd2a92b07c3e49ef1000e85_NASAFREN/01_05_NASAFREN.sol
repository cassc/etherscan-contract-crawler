// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Frens of North American Surveillance Association
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    For those who we appreciate.    //
//                                    //
//                                    //
////////////////////////////////////////


contract NASAFREN is ERC721Creator {
    constructor() ERC721Creator("Frens of North American Surveillance Association", "NASAFREN") {}
}