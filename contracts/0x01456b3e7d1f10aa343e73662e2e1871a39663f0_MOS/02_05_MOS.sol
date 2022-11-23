// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MOSAICS
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


contract MOS is ERC721Creator {
    constructor() ERC721Creator("MOSAICS", "MOS") {}
}