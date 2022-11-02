// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tori
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//     ____  __  ____  __      //
//    (_  _)/  \(  _ \(  )     //
//      )( (  O ))   / )(      //
//     (__) \__/(__\_)(__)     //
//                             //
//                             //
/////////////////////////////////


contract TORI is ERC721Creator {
    constructor() ERC721Creator("Tori", "TORI") {}
}