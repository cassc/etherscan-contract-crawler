// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: i0dine editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//                                                      //
//            ,d8       ,a8888a,             ,d8        //
//          ,d888     ,8P"'  `"Y8,         ,d888        //
//        ,d8" 88    ,8P        Y8,      ,d8" 88        //
//      ,d8"   88    88          88    ,d8"   88        //
//    ,d8"     88    88          88  ,d8"     88        //
//    8888888888888  `8b        d8'  8888888888888      //
//             88     `8ba,  ,ad8'            88        //
//             88       "Y8888P"              88        //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract i0dine is ERC1155Creator {
    constructor() ERC1155Creator("i0dine editions", "i0dine") {}
}