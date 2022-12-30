// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Linda Kristiansen - Claims
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//       _       _  __     ____   _          //
//      |"|     |"|/ /  U /"___| |"|         //
//    U | | u   | ' /   \| | u U | | u       //
//     \| |/__U/| . \\u  | |/__ \| |/__      //
//      |_____| |_|\_\    \____| |_____|     //
//      //  \\,-,>> \\,-._// \\  //  \\      //
//     (_")("_)\.)   (_/(__)(__)(_")("_)     //
//                                           //
//                                           //
///////////////////////////////////////////////


contract LKCL is ERC1155Creator {
    constructor() ERC1155Creator("Linda Kristiansen - Claims", "LKCL") {}
}