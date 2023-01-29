// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: True Faces
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//                                     //
//    ╔╦╗┬─┐┬ ┬┌─┐  ╔═╗┌─┐┌─┐┌─┐┌─┐    //
//     ║ ├┬┘│ │├┤   ╠╣ ├─┤│  ├┤ └─┐    //
//     ╩ ┴└─└─┘└─┘  ╚  ┴ ┴└─┘└─┘└─┘    //
//                                     //
//                                     //
//                                     //
/////////////////////////////////////////


contract TF is ERC721Creator {
    constructor() ERC721Creator("True Faces", "TF") {}
}