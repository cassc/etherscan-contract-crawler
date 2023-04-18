// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dinner of the Posh Cosplayers
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//                                            //
//    ██████  ██ ██████   ██████   ██████     //
//    ██   ██ ██ ██   ██ ██    ██ ██          //
//    ██   ██ ██ ██████  ██    ██ ██          //
//    ██   ██ ██ ██      ██    ██ ██          //
//    ██████  ██ ██       ██████   ██████     //
//                                            //
//                                            //
//                                            //
//                                            //
////////////////////////////////////////////////


contract DIPOC is ERC721Creator {
    constructor() ERC721Creator("Dinner of the Posh Cosplayers", "DIPOC") {}
}