// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: tochi pass
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//      __                .__    .__     //
//    _/  |_  ____   ____ |  |__ |__|    //
//    \   __\/  _ \_/ ___\|  |  \|  |    //
//     |  | (  <_> )  \___|   Y  \  |    //
//     |__|  \____/ \___  >___|  /__|    //
//                      \/     \/        //
//                                       //
//                                       //
///////////////////////////////////////////


contract TOCHIPASS is ERC1155Creator {
    constructor() ERC1155Creator("tochi pass", "TOCHIPASS") {}
}