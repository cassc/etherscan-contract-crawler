// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Heaven points they
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                //
//    Chen Qilin, as the host of the Heavenly Way system, can also spend the Heavenly Way points to buy food, weapons, practices, martial arts, Avatar, mystical arts, and medicinal herbs in the system mall.                    //
//                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                //
//    System mall all kinds of goods, only you can not think of, no can not buy.                                                                                                                                                  //
//                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                //
//    In addition, the Tiandao building can also shield any existence of snooping, suppression of all the strong, as long as the other side into the Tiandao building, life and death will be held in the hands of Chen Qilin.    //
//                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HPT is ERC721Creator {
    constructor() ERC721Creator("Heaven points they", "HPT") {}
}