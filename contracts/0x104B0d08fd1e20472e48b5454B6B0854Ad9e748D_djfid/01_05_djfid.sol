// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: djfid editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//     _____       __     ______   __     _____        //
//    /\  __-.    /\ \   /\  ___\ /\ \   /\  __-.      //
//    \ \ \/\ \  _\_\ \  \ \  __\ \ \ \  \ \ \/\ \     //
//     \ \____- /\_____\  \ \_\    \ \_\  \ \____-     //
//      \/____/ \/_____/   \/_/     \/_/   \/____/     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract djfid is ERC1155Creator {
    constructor() ERC1155Creator("djfid editions", "djfid") {}
}