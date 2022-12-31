// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Karinjini
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//               __                           //
//    |__/  /\  |__) | |\ |    | | |\ | |     //
//    |  \ /~~\ |  \ | | \| \__/ | | \| |     //
//                                            //
//                                            //
////////////////////////////////////////////////


contract Karinjini is ERC721Creator {
    constructor() ERC721Creator("Karinjini", "Karinjini") {}
}