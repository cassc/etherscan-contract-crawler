// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Imaterialism
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//         _____         //
//      __|_    |__      //
//     |    |      |     //
//     |    |      |     //
//     |____|    __|     //
//        |_____|        //
//                       //
//                       //
//                       //
///////////////////////////


contract IMTRLSM is ERC721Creator {
    constructor() ERC721Creator("Imaterialism", "IMTRLSM") {}
}