// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PAINT PFP MINT PASSES
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//                                                  //
//       ▄▄▄▄▀ ██  ▀▄    ▄ █    ████▄ █▄▄▄▄         //
//    ▀▀▀ █    █ █   █  █  █    █   █ █  ▄▀         //
//        █    █▄▄█   ▀█   █    █   █ █▀▀▌          //
//       █     █  █   █    ███▄ ▀████ █  █          //
//      ▀         █ ▄▀         ▀        █           //
//               █                     ▀            //
//              ▀                                   //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract PAINT is ERC1155Creator {
    constructor() ERC1155Creator("PAINT PFP MINT PASSES", "PAINT") {}
}