// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BL4CK
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    ___.   .__                 __        //
//    \_ |__ |  | _____    ____ |  | __    //
//     | __ \|  | \__  \ _/ ___\|  |/ /    //
//     | \_\ \  |__/ __ \\  \___|    <     //
//     |___  /____(____  /\___  >__|_ \    //
//         \/          \/     \/     \/    //
//                                         //
//                                         //
/////////////////////////////////////////////


contract BLK is ERC1155Creator {
    constructor() ERC1155Creator("BL4CK", "BLK") {}
}