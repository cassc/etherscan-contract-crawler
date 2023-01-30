// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BAG$ 4 BAG$
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//     ______________               //
//    |              |       BAG    //
//    |              |              //
//    |   O      O   |              //
//    |              |              //
//    |     ____     |              //
//    |              |              //
//    |              |              //
//    |/\/\/\/\/\/\/\|              //
//                                  //
//                                  //
//////////////////////////////////////


contract BAG is ERC1155Creator {
    constructor() ERC1155Creator("BAG$ 4 BAG$", "BAG") {}
}