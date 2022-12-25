// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: White Xmas
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    a 1:1 cube in “snow” white                                                          //
//                                                                                        //
//    nod to the Beatles’ The White Album                                                 //
//                                                                                        //
//    Happy Holidays! 💗🌸                                                                //
//                                                                                        //
//    OE- all proceeds will be donated to protect endangered animals within war zones.    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract FAMz is ERC1155Creator {
    constructor() ERC1155Creator("White Xmas", "FAMz") {}
}