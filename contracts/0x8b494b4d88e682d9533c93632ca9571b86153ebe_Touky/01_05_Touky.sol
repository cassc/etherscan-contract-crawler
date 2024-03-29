// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Touky333
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//     _____ _____ _   _ _   ____   _______  _____  _____     //
//    |_   _|  _  | | | | | / /\ \ / /____ ||____ ||____ |    //
//      | | | | | | | | | |/ /  \ V /    / /    / /    / /    //
//      | | | | | | | | |    \   \ /     \ \    \ \    \ \    //
//      | | \ \_/ / |_| | |\  \  | | .___/ /.___/ /.___/ /    //
//      \_/  \___/ \___/\_| \_/  \_/ \____/ \____/ \____/     //
//                                                            //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract Touky is ERC721Creator {
    constructor() ERC721Creator("Touky333", "Touky") {}
}