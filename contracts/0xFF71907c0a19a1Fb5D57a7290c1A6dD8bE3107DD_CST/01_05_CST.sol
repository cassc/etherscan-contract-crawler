// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: cat's space-time
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//    lovely and sometimes bewitching girl.    //
//    Cute is scary.                           //
//                                             //
//    可愛らしく、時に妖しい女の子。                          //
//    あなたの心を掴み、揺さぶり、誘い込む。                      //
//    そんな子たち。                                  //
//                                             //
//    cat's space-time                         //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract CST is ERC1155Creator {
    constructor() ERC1155Creator("cat's space-time", "CST") {}
}