// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ChristmasToast
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//     .--.     //
//    :_,. :    //
//      ,','    //
//     :_;      //
//     :_;      //
//              //
//              //
//////////////////


contract XMAS is ERC721Creator {
    constructor() ERC721Creator("ChristmasToast", "XMAS") {}
}