// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DIVINE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    DDDDD   VV     VV NN   NN     //
//    DD  DD  VV     VV NNN  NN     //
//    DD   DD  VV   VV  NN N NN     //
//    DD   DD   VV VV   NN  NNN     //
//    DDDDDD     VVV    NN   NN     //
//                                  //
//                                  //
//                                  //
//////////////////////////////////////


contract DVN is ERC1155Creator {
    constructor() ERC1155Creator("DIVINE", "DVN") {}
}