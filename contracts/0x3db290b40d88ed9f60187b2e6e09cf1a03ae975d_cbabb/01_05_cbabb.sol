// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cycles by ArinaBB
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//                                                //
//                        .__                     //
//      ____ ___.__. ____ |  |   ____   ______    //
//    _/ ___<   |  |/ ___\|  | _/ __ \ /  ___/    //
//    \  \___\___  \  \___|  |_\  ___/ \___ \     //
//     \___  > ____|\___  >____/\___  >____  >    //
//         \/\/         \/          \/     \/     //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract cbabb is ERC1155Creator {
    constructor() ERC1155Creator("Cycles by ArinaBB", "cbabb") {}
}