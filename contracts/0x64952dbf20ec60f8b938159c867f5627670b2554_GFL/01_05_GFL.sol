// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GiorgioF
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////
//                           //
//                           //
//                           //
//      _              _     //
//     / `._  __  ._  /_`    //
//    /_;//_///_///_//       //
//            _/             //
//                           //
//                           //
//                           //
///////////////////////////////


contract GFL is ERC1155Creator {
    constructor() ERC1155Creator("GiorgioF", "GFL") {}
}