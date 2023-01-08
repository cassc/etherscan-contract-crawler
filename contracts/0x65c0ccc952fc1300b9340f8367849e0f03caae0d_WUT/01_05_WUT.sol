// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: testerc721
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//                                     //
//                                     //
//      _____ _____  ___.__. ____      //
//     /     \\__  \<   |  |/  _ \     //
//    |  Y Y  \/ __ \\___  (  <_> )    //
//    |__|_|  (____  / ____|\____/     //
//          \/     \/\/                //
//                                     //
//                                     //
//                                     //
/////////////////////////////////////////


contract WUT is ERC721Creator {
    constructor() ERC721Creator("testerc721", "WUT") {}
}