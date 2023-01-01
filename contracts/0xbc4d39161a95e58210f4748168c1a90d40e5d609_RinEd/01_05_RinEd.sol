// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Deriniti Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//                                     //
//       __                            //
//      /  )                 _/_       //
//     /  / _  __  o ____  o /  o      //
//    /__/_</_/ (_<_/ / <_<_<__<_      //
//                                     //
//                                     //
//       __                            //
//      /  `   /  _/_                  //
//     /--  __/ o /  o __ ____  _      //
//    (___,(_/_<_<__<_(_)/ / <_/_)_    //
//                                     //
//                                     //
//                                     //
//                                     //
//                                     //
/////////////////////////////////////////


contract RinEd is ERC1155Creator {
    constructor() ERC1155Creator("Deriniti Editions", "RinEd") {}
}