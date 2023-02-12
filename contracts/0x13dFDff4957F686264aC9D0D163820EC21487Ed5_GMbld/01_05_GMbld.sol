// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GM Builders
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//                                                    //
//                                                    //
//                                                    //
//               /         / /    |                   //
//     ___  _ _ (___        (  ___| ___  ___  ___     //
//    |   )| | )|   )|   )| | |   )|___)|   )|___     //
//    |__/ |  / |__/ |__/ | | |__/ |__  |     __/     //
//    __/                                             //
//                                                    //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract GMbld is ERC1155Creator {
    constructor() ERC1155Creator("GM Builders", "GMbld") {}
}