// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Last South Pacific Kingdom
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//                                                                         //
//    ,-,-,-.                             ,---.                 .          //
//    `,| | |   . ,-. . ,-,-. . . ,-,-.   |  -'  ,-. ,-. .  , . |- . .     //
//      | ; | . | | | | | | | | | | | |   |  ,-' |   ,-| | /  | |  | |     //
//      '   `-' ' ' ' ' ' ' ' `-^ ' ' '   `---|  '   `-^ `'   ' `' `-|     //
//                                         ,-.|                     /|     //
//                                         `-+'                    `-'     //
//                                                                         //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////


contract TLSPK is ERC721Creator {
    constructor() ERC721Creator("The Last South Pacific Kingdom", "TLSPK") {}
}