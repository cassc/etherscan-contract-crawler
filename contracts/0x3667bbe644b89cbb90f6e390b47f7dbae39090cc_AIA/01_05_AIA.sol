// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mr_Mousse
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//                                                                                        //
//    O~~       O~~O~~~~~~~    O~~       O~~                                              //
//    O~ O~~   O~~~O~~    O~~  O~ O~~   O~~~                                              //
//    O~~ O~~ O O~~O~~    O~~  O~~ O~~ O O~~   O~~    O~~  O~~ O~~~~  O~~~~    O~~        //
//    O~~  O~~  O~~O~ O~~      O~~  O~~  O~~ O~~  O~~ O~~  O~~O~~    O~~     O~   O~~     //
//    O~~   O~  O~~O~~  O~~    O~~   O~  O~~O~~    O~~O~~  O~~  O~~~   O~~~ O~~~~~ O~~    //
//    O~~       O~~O~~    O~~  O~~       O~~ O~~  O~~ O~~  O~~    O~~    O~~O~            //
//    O~~       O~~O~~      O~~O~~       O~~   O~~      O~~O~~O~~ O~~O~~ O~~  O~~~~       //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract AIA is ERC721Creator {
    constructor() ERC721Creator("Mr_Mousse", "AIA") {}
}