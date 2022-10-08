// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Absolute Minimum
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////
//                                                                                  //
//                                                                                  //
//    ___                                                                           //
//      | |_   _     /\  |_   _  _  |    _|_  _    |\/| o ._  o ._ _      ._ _      //
//      | | | (/_   /--\ |_) _> (_) | |_| |_ (/_   |  | | | | | | | | |_| | | |     //
//                                                                                  //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////


contract TAMIN is ERC721Creator {
    constructor() ERC721Creator("The Absolute Minimum", "TAMIN") {}
}