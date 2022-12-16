// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Isabel Bérénos
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//          :::::::::::       ::::::::           :::      //
//             :+:          :+:    :+:        :+: :+:     //
//            +:+          +:+              +:+   +:+     //
//           +#+          +#++:++#++      +#++:++#++:     //
//          +#+                 +#+      +#+     +#+      //
//         #+#          #+#    #+#      #+#     #+#       //
//    ###########       ########       ###     ###        //
//                                                        //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract IB is ERC721Creator {
    constructor() ERC721Creator(unicode"Isabel Bérénos", "IB") {}
}