// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rare Precious Gemstones
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                              //
//                                                                                                              //
//          O~                O~~           O~~               O~~~~~~~~                                         //
//         O~ ~~              O~~           O~~               O~~                      O~                       //
//        O~  O~~    O~ O~~~O~O~ O~O~ O~~   O~~O~~  O~~ O~~~~ O~~      O~~  O~~ O~~~~       O~~    O~~ O~~      //
//       O~~   O~~    O~~     O~~  O~  O~~  O~~O~~  O~~O~~    O~~~~~~  O~~  O~~O~~    O~~ O~~  O~~  O~~  O~~    //
//      O~~~~~~ O~~   O~~     O~~  O~   O~~ O~~O~~  O~~  O~~~ O~~      O~~  O~~  O~~~ O~~O~~    O~~ O~~  O~~    //
//     O~~       O~~  O~~     O~~  O~~ O~~  O~~O~~  O~~    O~~O~~      O~~  O~~    O~~O~~ O~~  O~~  O~~  O~~    //
//    O~~         O~~O~~~      O~~ O~~     O~~~  O~~O~~O~~ O~~O~~        O~~O~~O~~ O~~O~~   O~~    O~~~  O~~    //
//                                 O~~                                                                          //
//                                                                                                              //
//                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RPG is ERC721Creator {
    constructor() ERC721Creator("Rare Precious Gemstones", "RPG") {}
}