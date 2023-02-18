// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: shroom
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                                                 //
//       _     _                                   //
//      / \___| |__  _ __ ___   ___  _ __ ___      //
//     /  / __| '_ \| '__/ _ \ / _ \| '_ ` _ \     //
//    /\_/\__ \ | | | | | (_) | (_) | | | | | |    //
//    \/  |___/_| |_|_|  \___/ \___/|_| |_| |_|    //
//                                                 //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract shr is ERC1155Creator {
    constructor() ERC1155Creator("shroom", "shr") {}
}