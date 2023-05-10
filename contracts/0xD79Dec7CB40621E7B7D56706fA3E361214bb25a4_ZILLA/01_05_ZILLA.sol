// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LIMITED EDITION $KEKO CARD
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    Kekozilla will stomp your nuts    //
//                                      //
//                                      //
//////////////////////////////////////////


contract ZILLA is ERC1155Creator {
    constructor() ERC1155Creator("LIMITED EDITION $KEKO CARD", "ZILLA") {}
}