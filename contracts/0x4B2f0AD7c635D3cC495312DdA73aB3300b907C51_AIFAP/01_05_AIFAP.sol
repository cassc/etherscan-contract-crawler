// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ana Isabel - Fine Art Photography
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//                                                                         //
//                    ___                                                  //
//      /\  ._   _.    |   _  _. |_   _  |   |_|  _       |  _ _|_ _|_     //
//     /--\ | | (_|   _|_ _> (_| |_) (/_ |   | | (/_ \/\/ | (/_ |_  |_     //
//                                                                         //
//                                                                         //
//                                                                         //
//                                                                         //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////


contract AIFAP is ERC721Creator {
    constructor() ERC721Creator("Ana Isabel - Fine Art Photography", "AIFAP") {}
}