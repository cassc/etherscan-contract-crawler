// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Steve Wanna Studio
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//      O~~ ~~    O~~                                         //
//    O~~    O~~  O~~                                         //
//     O~~      O~O~ O~   O~~    O~~     O~~   O~~            //
//       O~~      O~~   O~   O~~  O~~   O~~  O~   O~~         //
//          O~~   O~~  O~~~~~ O~~  O~~ O~~  O~~~~~ O~~        //
//    O~~    O~~  O~~  O~           O~O~~   O~                //
//      O~~ ~~     O~~   O~~~~       O~~      O~~~~           //
//                                                            //
//    O~~        O~~                                          //
//    O~~        O~~                                          //
//    O~~   O~   O~~   O~~    O~~ O~~  O~~ O~~     O~~        //
//    O~~  O~~   O~~ O~~  O~~  O~~  O~~ O~~  O~~ O~~  O~~     //
//    O~~ O~ O~~ O~~O~~   O~~  O~~  O~~ O~~  O~~O~~   O~~     //
//    O~ O~    O~~~~O~~   O~~  O~~  O~~ O~~  O~~O~~   O~~     //
//    O~~        O~~  O~~ O~~~O~~~  O~~O~~~  O~~  O~~ O~~~    //
//                                                            //
//      O~~ ~~    O~~               O~~                       //
//    O~~    O~~  O~~               O~~ O~                    //
//     O~~      O~O~ O~O~~  O~~     O~~      O~~              //
//       O~~      O~~  O~~  O~~ O~~ O~~O~~ O~~  O~~           //
//          O~~   O~~  O~~  O~~O~   O~~O~~O~~    O~~          //
//    O~~    O~~  O~~  O~~  O~~O~   O~~O~~ O~~  O~~           //
//      O~~ ~~     O~~   O~~O~~ O~~ O~~O~~   O~~              //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract SyWS is ERC721Creator {
    constructor() ERC721Creator("Steve Wanna Studio", "SyWS") {}
}