// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: vividcat
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    啥韭菜，都是我的天使客户，你竟然说他们是韭菜。    //
//                               //
//                               //
///////////////////////////////////


contract vividcat is ERC721Creator {
    constructor() ERC721Creator("vividcat", "vividcat") {}
}