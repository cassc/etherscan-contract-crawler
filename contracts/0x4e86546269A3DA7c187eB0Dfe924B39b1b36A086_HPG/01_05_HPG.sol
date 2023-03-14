// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HanPug
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//                        //
//      _  _ ___  ___     //
//     | || | _ \/ __|    //
//     | __ |  _/ (_ |    //
//     |_||_|_|  \___|    //
//                        //
//                        //
//                        //
//                        //
////////////////////////////


contract HPG is ERC721Creator {
    constructor() ERC721Creator("HanPug", "HPG") {}
}