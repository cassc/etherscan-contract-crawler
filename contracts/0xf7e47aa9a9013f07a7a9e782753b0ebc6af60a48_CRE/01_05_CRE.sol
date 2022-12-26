// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CRANIUM EDITION
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////
//                                //
//                                //
//     ██████ ██████  ███████     //
//    ██      ██   ██ ██          //
//    ██      ██████  █████       //
//    ██      ██   ██ ██          //
//     ██████ ██   ██ ███████     //
//                                //
//                                //
//                                //
//                                //
////////////////////////////////////


contract CRE is ERC721Creator {
    constructor() ERC721Creator("CRANIUM EDITION", "CRE") {}
}