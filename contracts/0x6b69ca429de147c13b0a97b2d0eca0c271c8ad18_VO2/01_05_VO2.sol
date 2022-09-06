// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VO2 Vault
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////
//                 //
//                 //
//    VO2 Group    //
//                 //
//                 //
/////////////////////


contract VO2 is ERC721Creator {
    constructor() ERC721Creator("VO2 Vault", "VO2") {}
}