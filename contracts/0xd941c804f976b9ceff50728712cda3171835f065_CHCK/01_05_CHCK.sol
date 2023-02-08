// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CHECKS IN THE MAIL
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////
//              //
//              //
//    CHECKS    //
//    IN        //
//    THE       //
//    MAIL      //
//              //
//              //
//////////////////


contract CHCK is ERC1155Creator {
    constructor() ERC1155Creator("CHECKS IN THE MAIL", "CHCK") {}
}