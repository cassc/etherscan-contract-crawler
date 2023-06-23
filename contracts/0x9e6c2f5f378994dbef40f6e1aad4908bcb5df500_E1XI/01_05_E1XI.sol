// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: E1even XI
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////
//                                //
//                                //
//       ___    _   _  __   __    //
//      / _/  ,'/  | |/,'  / /    //
//     / _/   //   /  /   / /     //
//    /___/  //  ,'_x_\  /_/      //
//                                //
//                                //
//                                //
////////////////////////////////////


contract E1XI is ERC1155Creator {
    constructor() ERC1155Creator("E1even XI", "E1XI") {}
}