// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SarahScript Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//                                                       //
//      ()                      ()                       //
//      /\                  /   /\                _/_    //
//     /  )  __.  __  __.  /_  /  )  _. __  o _   /      //
//    /__/__(_/|_/ (_(_/|_/ /_/__/__(__/ (_<_/_)_<__     //
//                                          /            //
//                                         '             //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract SFR is ERC1155Creator {
    constructor() ERC1155Creator("SarahScript Editions", "SFR") {}
}