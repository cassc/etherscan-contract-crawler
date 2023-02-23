// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DanCTRL'OE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//         _                  _        _     //
//        | |                | |      | |    //
//      __| | __ _ _ __   ___| |_ _ __| |    //
//     / _` |/ _` | '_ \ / __| __| '__| |    //
//    | (_| | (_| | | | | (__| |_| |  | |    //
//     \__,_|\__,_|_| |_|\___|\__|_|  |_|    //
//                                           //
//                                           //
//                                           //
//                                           //
///////////////////////////////////////////////


contract DANOE is ERC1155Creator {
    constructor() ERC1155Creator("DanCTRL'OE", "DANOE") {}
}