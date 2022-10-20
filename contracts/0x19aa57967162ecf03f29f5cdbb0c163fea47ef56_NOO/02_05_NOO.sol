// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: New Ornament by Oxen
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////
//                                                                 //
//                                                                 //
//                                                                 //
//    ,-,-.               ,---.                           .        //
//    ` | |   ,-. . , ,   |   | ,-. ,-. ,-. ,-,-. ,-. ,-. |-       //
//      | |-. |-' |/|/    |   | |   | | ,-| | | | |-' | | |        //
//     ,' `-' `-' ' '     `---' '   ' ' `-^ ' ' ' `-' ' ' `'       //
//                                                                 //
//                                                                 //
//                                                                 //
//                                                                 //
//                                                                 //
//                                                                 //
/////////////////////////////////////////////////////////////////////


contract NOO is ERC721Creator {
    constructor() ERC721Creator("New Ornament by Oxen", "NOO") {}
}