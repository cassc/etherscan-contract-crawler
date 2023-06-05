// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BEFE Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//                                                              //
//    ██████╗ ███████╗███████╗███████╗                          //
//    ██╔══██╗██╔════╝██╔════╝██╔════╝                          //
//    ██████╔╝█████╗  █████╗  █████╗                            //
//    ██╔══██╗██╔══╝  ██╔══╝  ██╔══╝                            //
//    ██████╔╝███████╗██║     ███████╗                          //
//    ╚═════╝ ╚══════╝╚═╝     ╚══════╝                          //
//                                                              //
//    Befe Editions                                             //
//    This contract includes edition works produced by Befe.    //
//    -                                                         //
//    https://twitter.com/befethemad                            //
//    https://www.instagram.com/bahadirefendi                   //
//                                                              //
//                                                              //
//                                                              //
//                                                              //
//                                                              //
//                                                              //
//                                                              //
//////////////////////////////////////////////////////////////////


contract BFE is ERC1155Creator {
    constructor() ERC1155Creator("BEFE Editions", "BFE") {}
}