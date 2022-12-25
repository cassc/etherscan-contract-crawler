// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Merry Christmas!
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//    I hope you have a wonderful Christmas!    //
//    素敵なクリスマスになりますように！                         //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract thmc is ERC1155Creator {
    constructor() ERC1155Creator("Merry Christmas!", "thmc") {}
}