// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: dasfruits
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//                                       //
//                  _                    //
//      _|  _.  _ _|_ ._    o _|_  _     //
//     (_| (_| _>  |  | |_| |  |_ _>     //
//                                       //
//                                       //
//                                       //
//                                       //
///////////////////////////////////////////


contract das is ERC1155Creator {
    constructor() ERC1155Creator("dasfruits", "das") {}
}