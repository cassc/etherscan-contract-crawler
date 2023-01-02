// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ATS - Foundation Nodes
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////
//                        //
//                        //
//                        //
//     ____ ____ ____     //
//    ||A |||T |||S ||    //
//    ||__|||__|||__||    //
//    |/__\|/__\|/__\|    //
//                        //
//                        //
//                        //
////////////////////////////


contract ATS is ERC1155Creator {
    constructor() ERC1155Creator("ATS - Foundation Nodes", "ATS") {}
}