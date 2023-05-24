// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pixel Core
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//       +--------------+       //
//       |.------------.|       //
//       ||            ||       //
//       ||   WŸN      ||       //
//       ||            ||       //
//       ||            ||       //
//       |+------------+|       //
//       +-..--------..-+       //
//       .--------------.       //
//      / /============\ \      //
//     / /==============\ \     //
//    /____________________\    //
//    \____________________/    //
//                              //
//                              //
//////////////////////////////////


contract PXLCORE is ERC721Creator {
    constructor() ERC721Creator("Pixel Core", "PXLCORE") {}
}