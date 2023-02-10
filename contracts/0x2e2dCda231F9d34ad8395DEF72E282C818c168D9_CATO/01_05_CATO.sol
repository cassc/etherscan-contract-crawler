// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cato
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//     ______     ______     ______   ______        //
//    /\  ___\   /\  __ \   /\__  _\ /\  __ \       //
//    \ \ \____  \ \  __ \  \/_/\ \/ \ \ \/\ \      //
//     \ \_____\  \ \_\ \_\    \ \_\  \ \_____\     //
//      \/_____/   \/_/\/_/     \/_/   \/_____/     //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract CATO is ERC1155Creator {
    constructor() ERC1155Creator("Cato", "CATO") {}
}