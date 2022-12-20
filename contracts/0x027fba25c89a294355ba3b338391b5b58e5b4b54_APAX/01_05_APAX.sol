// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Stairway to opportunity
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//    An opportunity for everyone to enjoy a photo NFT!     //
//    Utility is art :)                                     //
//    -apax                                                 //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract APAX is ERC1155Creator {
    constructor() ERC1155Creator("Stairway to opportunity", "APAX") {}
}