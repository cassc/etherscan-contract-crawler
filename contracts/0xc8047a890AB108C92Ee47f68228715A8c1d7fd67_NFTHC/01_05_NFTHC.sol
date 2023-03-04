// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Celestial Nomad
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//                                      //
//     _  _  ____  ____  _   _  ___     //
//    ( \( )( ___)(_  _)( )_( )/ __)    //
//     )  (  )__)   )(   ) _ (( (__     //
//    (_)\_)(__)   (__) (_) (_)\___)    //
//                                      //
//                                      //
//                                      //
//////////////////////////////////////////


contract NFTHC is ERC1155Creator {
    constructor() ERC1155Creator("Celestial Nomad", "NFTHC") {}
}