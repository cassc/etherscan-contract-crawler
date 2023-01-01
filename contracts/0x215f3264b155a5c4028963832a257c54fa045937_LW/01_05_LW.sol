// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lone Walk
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//      _                      __        __    _ _        //
//     | |    ___  _ __   ___  \ \      / /_ _| | | __    //
//     | |   / _ \| '_ \ / _ \  \ \ /\ / / _` | | |/ /    //
//     | |__| (_) | | | |  __/   \ V  V / (_| | |   <     //
//     |_____\___/|_| |_|\___|    \_/\_/ \__,_|_|_|\_\    //
//                                                        //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract LW is ERC1155Creator {
    constructor() ERC1155Creator("Lone Walk", "LW") {}
}