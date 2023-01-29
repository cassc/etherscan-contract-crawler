// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CH
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////
//                              //
//                              //
//     ::::::::  :::    :::     //
//    :+:    :+: :+:    :+:     //
//    +:+        +:+    +:+     //
//    +#+        +#++:++#++     //
//    +#+        +#+    +#+     //
//    #+#    #+# #+#    #+#     //
//     ########  ###    ###     //
//                              //
//                              //
//////////////////////////////////


contract CH is ERC1155Creator {
    constructor() ERC1155Creator("CH", "CH") {}
}