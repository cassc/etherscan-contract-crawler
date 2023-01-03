// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: おまけだよ
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////
//                  //
//                  //
//    おまけ配布ページだよ    //
//                  //
//                  //
//////////////////////


contract OMK is ERC1155Creator {
    constructor() ERC1155Creator(unicode"おまけだよ", "OMK") {}
}