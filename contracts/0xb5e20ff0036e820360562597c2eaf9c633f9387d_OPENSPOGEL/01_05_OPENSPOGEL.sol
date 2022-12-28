// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Spogel Open Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//    /~\|~)[~|\ |  (~|~)/~\|~_[~|     //
//    \_/|~ [_| \|  _)|~ \_/|_|[_|_    //
//                                     //
//                                     //
/////////////////////////////////////////


contract OPENSPOGEL is ERC1155Creator {
    constructor() ERC1155Creator("Spogel Open Editions", "OPENSPOGEL") {}
}