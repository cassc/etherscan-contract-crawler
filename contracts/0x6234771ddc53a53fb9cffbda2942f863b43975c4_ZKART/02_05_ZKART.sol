// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Zac Kenny
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//    A collection of editions and 1/1s by Zac Kenny.     //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract ZKART is ERC721Creator {
    constructor() ERC721Creator("Zac Kenny", "ZKART") {}
}