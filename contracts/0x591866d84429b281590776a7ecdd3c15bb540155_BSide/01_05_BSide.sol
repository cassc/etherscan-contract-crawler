// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Trippy Tarot B-Sides (Open Edition)
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//    ___  __     __   __         ___       __   __  ___     __      __     __   ___  __      //
//     |  |__) | |__) |__) \ /     |   /\  |__) /  \  |     |__) __ /__` | |  \ |__  /__`     //
//     |  |  \ | |    |     |      |  /~~\ |  \ \__/  |     |__)    .__/ | |__/ |___ .__/     //
//                                                                                            //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract BSide is ERC1155Creator {
    constructor() ERC1155Creator("Trippy Tarot B-Sides (Open Edition)", "BSide") {}
}