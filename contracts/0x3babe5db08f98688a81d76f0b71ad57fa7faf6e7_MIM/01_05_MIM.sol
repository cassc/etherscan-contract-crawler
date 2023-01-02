// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MIMcrypt
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    MIMcrypt    //
//                //
//                //
////////////////////


contract MIM is ERC721Creator {
    constructor() ERC721Creator("MIMcrypt", "MIM") {}
}