// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Abstract Thoughts
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                         //
//                                                                                                                                                         //
//                                                                                                                                                         //
//          O)       O))               O))                            O))         O))) O))))))                                             O))             //
//         O) ))     O))               O))                            O))              O))    O))                                O))       O))             //
//        O)  O))    O))       O)))) O)O) O)O) O)))   O))       O)))O)O) O)            O))    O))        O))    O))  O))   O))   O))     O)O) O) O))))     //
//       O))   O))   O)) O))  O))      O))   O))    O))  O))  O))     O))              O))    O) O)    O))  O)) O))  O)) O))  O))O) O)     O))  O))        //
//      O)))))) O))  O))   O))  O)))   O))   O))   O))   O)) O))      O))              O))    O))  O))O))    O))O))  O))O))   O))O))  O))  O))    O)))     //
//     O))       O)) O))   O))    O))  O))   O))   O))   O))  O))     O))              O))    O)   O)) O))  O)) O))  O)) O))  O))O)   O))  O))      O))    //
//    O))         O))O)) O))  O)) O))   O)) O)))     O)) O)))   O)))   O))             O))    O))  O))   O))      O))O))     O)) O))  O))   O)) O)) O))    //
//                                                                                                                        O))                              //
//                                                                                                                                                         //
//    Abstract Thoughts is a collection that was born after a visit I made to Fiumara D'Arte in Sicily.                                                    //
//    Originally minted on another platform, one year ago, it finds a home with a smart contract of mine.                                                  //
//                                                                                                                                                         //
//                                                                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ABTH is ERC721Creator {
    constructor() ERC721Creator("Abstract Thoughts", "ABTH") {}
}