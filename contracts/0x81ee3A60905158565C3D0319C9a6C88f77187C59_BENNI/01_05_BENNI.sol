// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BENNI Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//    BBBBB   EEEEE  N   N  N   N  I      //
//    B    B  E      NN  N  NN  N  I      //
//    BBBBB   EEEE   N N N  N N N  I      //
//    B    B  E      N  NN  N  NN  I      //
//    BBBBB   EEEEE  N   N  N   N  I      //
//                                        //
//                                        //
////////////////////////////////////////////


contract BENNI is ERC1155Creator {
    constructor() ERC1155Creator("BENNI Editions", "BENNI") {}
}