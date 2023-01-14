// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ordinary Experiences
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                 //
//                                                                                                 //
//                                                                                                 //
//                                                                                                 //
//        O~~~~                 O~~                                                                //
//      O~~    O~~              O~~ O~                                                             //
//    O~~        O~~O~ O~~~     O~~   O~~ O~~     O~~    O~ O~~~O~~   O~~                          //
//    O~~        O~~ O~~    O~~ O~~O~~ O~~  O~~ O~~  O~~  O~~    O~~ O~~                           //
//    O~~        O~~ O~~   O~   O~~O~~ O~~  O~~O~~   O~~  O~~      O~~~                            //
//      O~~     O~~  O~~   O~   O~~O~~ O~~  O~~O~~   O~~  O~~       O~~                            //
//        O~~~~     O~~~    O~~ O~~O~~O~~~  O~~  O~~ O~~~O~~~      O~~                             //
//                                                               O~~                               //
//    O~~~~~~~~                                                                                    //
//    O~~                                         O~                                               //
//    O~~      O~~   O~~O~ O~~     O~~    O~ O~~~      O~~    O~~ O~~     O~~~   O~~     O~~~~     //
//    O~~~~~~    O~ O~~ O~  O~~  O~   O~~  O~~   O~~ O~   O~~  O~~  O~~ O~~    O~   O~~ O~~        //
//    O~~         O~    O~   O~~O~~~~~ O~~ O~~   O~~O~~~~~ O~~ O~~  O~~O~~    O~~~~~ O~~  O~~~     //
//    O~~       O~  O~~ O~~ O~~ O~         O~~   O~~O~         O~~  O~~ O~~   O~            O~~    //
//    O~~~~~~~~O~~   O~~O~~       O~~~~   O~~~   O~~  O~~~~   O~~~  O~~   O~~~  O~~~~   O~~ O~~    //
//                      O~~                                                                        //
//                                                                                                 //
//                                                                                                 //
//                                                                                                 //
//                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////


contract OE is ERC721Creator {
    constructor() ERC721Creator("Ordinary Experiences", "OE") {}
}