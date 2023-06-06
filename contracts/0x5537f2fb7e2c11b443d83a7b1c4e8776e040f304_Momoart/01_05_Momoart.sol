// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Momo Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//    ___  __    __     _____  ___  __    __     _____     ____     ____  ___  __    __       //
//    `MM 6MMb  6MMb   6MMMMMb `MM 6MMb  6MMb   6MMMMMb   6MMMMb   6MMMMb\`MM 6MMb  6MMb      //
//     MM69 `MM69 `Mb 6M'   `Mb MM69 `MM69 `Mb 6M'   `Mb MM'  `Mb MM'    ` MM69 `MM69 `Mb     //
//     MM'   MM'   MM MM     MM MM'   MM'   MM MM     MM      ,MM YM.      MM'   MM'   MM     //
//     MM    MM    MM MM     MM MM    MM    MM MM     MM     ,MM'  YMMMMb  MM    MM    MM     //
//     MM    MM    MM MM     MM MM    MM    MM MM     MM   ,M'         `Mb MM    MM    MM     //
//     MM    MM    MM YM.   ,M9 MM    MM    MM YM.   ,M9 ,M'      L    ,MM MM    MM    MM     //
//    _MM_  _MM_  _MM_ YMMMMM9 _MM_  _MM_  _MM_ YMMMMM9  MMMMMMMM MYMMMM9 _MM_  _MM_  _MM_    //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract Momoart is ERC1155Creator {
    constructor() ERC1155Creator("Momo Editions", "Momoart") {}
}