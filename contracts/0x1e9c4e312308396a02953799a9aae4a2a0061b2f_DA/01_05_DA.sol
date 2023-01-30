// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Degen arts
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                 //
//                                                                                                                 //
//    Hey, I'm a digital artist from India trying to express my emotions and feelings through the medium of 3d     //
//    art. I love to create whatever comes into my mind or what inspires me. It genuinely makes me happy.          //
//    I like challenges and I hope you like my work. Thanks.                                                       //
//                                                                                                                 //
//                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DA is ERC1155Creator {
    constructor() ERC1155Creator("Degen arts", "DA") {}
}