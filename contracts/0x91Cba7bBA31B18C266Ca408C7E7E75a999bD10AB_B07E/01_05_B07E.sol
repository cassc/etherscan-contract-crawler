// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: B07 Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////
//                              //
//                              //
//                              //
//                              //
//       (      )     )         //
//     ( )\  ( /(  ( /((        //
//     )((_) )\()) )\())\       //
//    ((_)_ ((_)\ ((_)((_)      //
//     | _ )/  (_)__  / __|     //
//     | _ \ () |  / /| _|      //
//     |___/\__/  /_/ |___|     //
//                              //
//                              //
//                              //
//                              //
//////////////////////////////////


contract B07E is ERC1155Creator {
    constructor() ERC1155Creator("B07 Editions", "B07E") {}
}