// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: From nothing to pre-existing
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                  //
//                                                                                                                  //
//    __, __,  _, _, _   _, _  _, ___ _,_ _ _, _  _,   ___  _,   __, __, __,    __, _  , _  _, ___ _ _, _  _,       //
//     |_  |_) / \ |\/|   |\ | / \  |  |_| | |\ | / _    |  / \   |_) |_) |_     |_  '\/  | (_   |  | |\ | / _      //
//     |   | \ \ / |  |   | \| \ /  |  | | | | \| \ /    |  \ /   |   | \ |   ~~ |    /\  | , )  |  | | \| \ /      //
//     ~   ~ ~  ~  ~  ~   ~  ~  ~   ~  ~ ~ ~ ~  ~  ~     ~   ~    ~   ~ ~ ~~~    ~~~ ~  ~ ~  ~   ~  ~ ~  ~  ~       //
//                                                                                                                  //
//                                                                                                                  //
//    "From nothing to pre-existing" is a series by Pedro Victor Brandão depicting different stages of chemical     //
//    paintings created without planning with expired instant films.                                                //
//                                                                                                                  //
//    2006-2008                                                                                                     //
//                                                                                                                  //
//                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FNTPE is ERC721Creator {
    constructor() ERC721Creator("From nothing to pre-existing", "FNTPE") {}
}