// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: IRL Alpha 🔥
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    888 888~-_   888          e          //
//    888 888   \  888         d8b         //
//    888 888    | 888        /Y88b        //
//    888 888   /  888       /  Y88b       //
//    888 888_-~   888      /____Y88b      //
//    888 888 ~-_  888____ /      Y88b     //
//                                         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract IRLA is ERC1155Creator {
    constructor() ERC1155Creator(unicode"IRL Alpha 🔥", "IRLA") {}
}