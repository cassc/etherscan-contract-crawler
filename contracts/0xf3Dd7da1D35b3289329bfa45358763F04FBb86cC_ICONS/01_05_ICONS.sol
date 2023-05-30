// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 𝐂𝐏𝐆: 𝐈𝐜𝐨𝐧𝐬 𝐨𝐟 𝐭𝐡𝐞 𝐈𝐧𝐭𝐞𝐫𝐧𝐞𝐭
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//                                       //
//       _|_|_|  _|_|_|      _|_|_|      //
//     _|        _|    _|  _|            //
//     _|        _|_|_|    _|  _|_|      //
//     _|        _|        _|    _|      //
//       _|_|_|  _|          _|_|_|      //
//                                       //
//                                       //
//                                       //
///////////////////////////////////////////


contract ICONS is ERC1155Creator {
    constructor() ERC1155Creator(unicode"𝐂𝐏𝐆: 𝐈𝐜𝐨𝐧𝐬 𝐨𝐟 𝐭𝐡𝐞 𝐈𝐧𝐭𝐞𝐫𝐧𝐞𝐭", "ICONS") {}
}