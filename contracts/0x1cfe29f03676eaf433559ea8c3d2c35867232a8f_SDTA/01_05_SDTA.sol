// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sublime Data
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//                        ,,        ,,    ,,                                                                        //
//     .M"""bgd          *MM      `7MM    db                                `7MM"""Yb.            mm                //
//    ,MI    "Y           MM        MM                                        MM    `Yb.          MM                //
//    `MMb.   `7MM  `7MM  MM,dMMb.  MM  `7MM  `7MMpMMMb.pMMMb.  .gP"Ya        MM     `Mb  ,6"Yb.mmMMmm  ,6"Yb.      //
//      `YMMNq. MM    MM  MM    `Mb MM    MM    MM    MM    MM ,M'   Yb       MM      MM 8)   MM  MM   8)   MM      //
//    .     `MM MM    MM  MM     M8 MM    MM    MM    MM    MM 8M""""""       MM     ,MP  ,pm9MM  MM    ,pm9MM      //
//    Mb     dM MM    MM  MM.   ,M9 MM    MM    MM    MM    MM YM.    ,       MM    ,dP' 8M   MM  MM   8M   MM      //
//    P"Ybmmd"  `Mbod"YML.P^YbmdP'.JMML..JMML..JMML  JMML  JMML.`Mbmmd'     .JMMmmmdP'   `Moo9^Yo.`Mbmo`Moo9^Yo.    //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SDTA is ERC721Creator {
    constructor() ERC721Creator("Sublime Data", "SDTA") {}
}