// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Life through Rose tinted glasses
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////
//                                                                //
//                                                                //
//          ___           ___           ___           ___         //
//                                                                //
//        /::\  \       /::\  \       /::\  \       /::\  \       //
//       /:/\:\  \     /:/\:\  \     /:/\ \  \     /:/\:\  \      //
//      /::\~\:\  \   /:/  \:\  \   _\:\~\ \  \   /::\~\:\  \     //
//     /:/\:\ \:\__\ /:/__/ \:\__\ /\ \:\ \ \__\ /:/\:\ \:\__\    //
//     \/_|::\/:/  / \:\  \ /:/  / \:\ \:\ \/__/ \:\~\:\ \/__/    //
//        |:|::/  /   \:\  /:/  /   \:\ \:\__\    \:\ \:\__\      //
//        |:|\/__/     \:\/:/  /     \:\/:/  /     \:\ \/__/      //
//        |:|  |        \::/  /       \::/  /       \:\__\        //
//         \|__|         \/__/         \/__/         \/__/        //
//                                                                //
//                                                                //
////////////////////////////////////////////////////////////////////


contract Iris00 is ERC1155Creator {
    constructor() ERC1155Creator("Life through Rose tinted glasses", "Iris00") {}
}