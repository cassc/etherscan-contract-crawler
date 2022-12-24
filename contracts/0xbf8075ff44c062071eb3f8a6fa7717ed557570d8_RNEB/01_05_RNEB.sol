// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Reflection Nebulae
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//                                                     //
//     __   ___        __    __  _____  ___   ___      //
//    ( (` | |_)      / /\  ( (`  | |  | |_) / / \     //
//    _)_) |_|_)     /_/--\ _)_)  |_|  |_| \ \_\_/     //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract RNEB is ERC721Creator {
    constructor() ERC721Creator("Reflection Nebulae", "RNEB") {}
}