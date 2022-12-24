// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Don't Change Your Avatar
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////
//                //
//                //
//    //🥷🏾\\    //
//    //🙏🏾\\    //
//    //🌊\\      //
//                //
//                //
////////////////////


contract AVATAR is ERC1155Creator {
    constructor() ERC1155Creator("Don't Change Your Avatar", "AVATAR") {}
}