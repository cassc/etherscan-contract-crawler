// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Emission Nebulae
/// @author: manifold.xyz

import "./ERC721Creator.sol";

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


contract ENEB is ERC721Creator {
    constructor() ERC721Creator("Emission Nebulae", "ENEB") {}
}