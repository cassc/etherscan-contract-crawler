// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dexter Danger
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//    ________  ________      _____       //
//    \______ \ \______ \    /     \      //
//     |    |  \ |    |  \  /  \ /  \     //
//     |    `   \|    `   \/    Y    \    //
//    /_______  /_______  /\____|__  /    //
//            \/        \/         \/     //
//                                        //
//                                        //
////////////////////////////////////////////


contract DDM is ERC1155Creator {
    constructor() ERC1155Creator("Dexter Danger", "DDM") {}
}