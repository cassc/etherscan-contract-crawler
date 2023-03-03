// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Alterlier Bidders Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////
//                             //
//                             //
//                             //
//     _____  _    _____       //
//    (  _  )( )  (_   _)      //
//    | (_) || |    | |        //
//    |  _  || |  _ | |        //
//    | | | || |_( )| |        //
//    (_) (_)(____/'(_)        //
//                             //
//                             //
//                             //
//                             //
//                             //
//                             //
//                             //
/////////////////////////////////


contract ALT is ERC1155Creator {
    constructor() ERC1155Creator("Alterlier Bidders Edition", "ALT") {}
}