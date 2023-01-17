// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FREE by JED XO
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    .----..----. .----..----.       //
//    | {_  | {}  }| {_  | {_         //
//    | |   | .-. \| {__ | {__        //
//    `-'   `-' `-'`----'`----'       //
//                                    //
//                                    //
////////////////////////////////////////


contract FJX is ERC1155Creator {
    constructor() ERC1155Creator("FREE by JED XO", "FJX") {}
}