// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BASIIC OPEN EDITION
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//    ██████   █████  ███████ ██ ██  ██████    //
//    ██   ██ ██   ██ ██      ██ ██ ██         //
//    ██████  ███████ ███████ ██ ██ ██         //
//    ██   ██ ██   ██      ██ ██ ██ ██         //
//    ██████  ██   ██ ███████ ██ ██  ██████    //
//                                             //
//    BASIIC OPEN EDITION 001, 2023            //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract BOO1 is ERC721Creator {
    constructor() ERC721Creator("BASIIC OPEN EDITION", "BOO1") {}
}