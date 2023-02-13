// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Anne's Odango Project
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//              ____   ____   ____             //
//             / __ \ / __ \ / __ \            //
//      ______| |  | | |  | | |  | |___        //
//     |______| |  | | |  | | |  | |___|       //
//            | |__| | |__| | |__| |           //
//             \____/ \____/ \____/            //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract AOP is ERC1155Creator {
    constructor() ERC1155Creator("Anne's Odango Project", "AOP") {}
}