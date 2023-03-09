// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Granny Mints
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////
//                                                                                //
//                                                                                //
//    GGGGGGGGG    RRRRRRRRR        A        N      N    N      N    Y       Y    //
//    G            R       R       A A       N N    N    N N    N     Y     Y     //
//    G            R       R      A   A      N  N   N    N  N   N      V   V      //
//    G    GGGG    RRRRRRRRR     AAAAAAA     N   N  N    N   N  N       Y Y       //
//    G    G  G    R   R        A       A    N    N N    N    N N        Y        //
//    G       G    R    R       A       A    N      N    N      N        Y        //
//    GGGGGGGGG    R     R      A       A    N      N    N      N        Y        //
//                                                                                //
//                                                                                //
////////////////////////////////////////////////////////////////////////////////////


contract GRANY is ERC1155Creator {
    constructor() ERC1155Creator("Granny Mints", "GRANY") {}
}