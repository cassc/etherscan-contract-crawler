// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: it's ringing...
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//            ____________            //
//          /   ,,____,,   \:.        //
//          |__| [][][] |__|:  :      //
//            /  [][][]  \   :  :     //
//           /   [][][]   \   :  :    //
//          /    [][][]    \   ..     //
//         |________________|         //
//                                    //
//                                    //
////////////////////////////////////////


contract ir is ERC1155Creator {
    constructor() ERC1155Creator("it's ringing...", "ir") {}
}