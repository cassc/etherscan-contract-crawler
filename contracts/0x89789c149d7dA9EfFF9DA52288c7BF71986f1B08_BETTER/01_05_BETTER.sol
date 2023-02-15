// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Better Together
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////
//                                                                   //
//                                                                   //
//                                                                   //
//                                                                   //
//      /_  _  -/--/- _   ,_     -/- _,_ __   _  -/- /_   _   ,_     //
//    _/_)_(/__/__/__(/__/ (_   _/__(_/_(_/__(/__/__/ (__(/__/ (_    //
//                                      _/_                          //
//                                     (/                            //
//                                                                   //
//                                                                   //
//                                                                   //
//                                                                   //
//                                                                   //
///////////////////////////////////////////////////////////////////////


contract BETTER is ERC1155Creator {
    constructor() ERC1155Creator("Better Together", "BETTER") {}
}