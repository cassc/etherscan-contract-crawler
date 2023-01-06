// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: beta
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//     ______     ______     ______   ______        //
//    /\  == \   /\  ___\   /\__  _\ /\  __ \       //
//    \ \  __<   \ \  __\   \/_/\ \/ \ \  __ \      //
//     \ \_____\  \ \_____\    \ \_\  \ \_\ \_\     //
//      \/_____/   \/_____/     \/_/   \/_/\/_/     //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract beta is ERC1155Creator {
    constructor() ERC1155Creator("beta", "beta") {}
}