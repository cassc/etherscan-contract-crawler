// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cosmo Danchin-Hamard
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//                                                            //
//        ___                                                 //
//      ,"___".    ____      ____     _ _____      ____       //
//      FJ---L]   F __ J    F ___J   J '_  _ `,   F __ J      //
//     J |   LJ  | |--| |  | '----_  | |_||_| |  | |--| |     //
//     | \___--. F L__J J  )-____  L F L LJ J J  F L__J J     //
//     J\_____/FJ\______/FJ\______/FJ__L LJ J__LJ\______/F    //
//      J_____F  J______F  J______F |__L LJ J__| J______F     //
//                                                            //
//                                                            //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract CDH is ERC1155Creator {
    constructor() ERC1155Creator("Cosmo Danchin-Hamard", "CDH") {}
}