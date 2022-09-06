// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: justchicken.xyz
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//    _T |_| _\~ ~|~   ( |-| | ( /< [- |\| _\~     //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract JCN is ERC721Creator {
    constructor() ERC721Creator("justchicken.xyz", "JCN") {}
}