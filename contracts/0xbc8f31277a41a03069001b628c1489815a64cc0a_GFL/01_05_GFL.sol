// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GiorgioF
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//      _              _      //
//     / `._  __  ._  /_`     //
//    /_;//_///_///_//        //
//            _/              //
//                            //
//                            //
//                            //
////////////////////////////////


contract GFL is ERC721Creator {
    constructor() ERC721Creator("GiorgioF", "GFL") {}
}