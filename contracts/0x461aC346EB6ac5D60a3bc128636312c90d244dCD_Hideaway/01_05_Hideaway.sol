// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hideaway
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//                            ,,,                           //
//                           {{{}}                          //
//                        ,,, ~Y~                           //
//                       {{}}} |/,,,                        //
//                        ~Y~ \|{{}}}                       //
//                        \|/ \|/~Y~                        //
//                        \|/ \|/\|/                        //
//                        \|/\\|/\|/                        //
//                        \|//\|/\|/                        //
//     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^    //
//                 This is all about darkness.              //
//                        Ivan Solyaev                      //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract Hideaway is ERC1155Creator {
    constructor() ERC1155Creator("Hideaway", "Hideaway") {}
}