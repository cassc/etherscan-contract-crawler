// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DCnfts
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                                                                                                 //
//                                                                                                                                 //
//                                                                                                                                 //
//                                                                                                                                 //
//                                                                                                                                 //
//    DDDDDDDDDDDDD                CCCCCCCCCCCCC                     ffffffffffffffff           tttt                               //
//    D::::::::::::DDD          CCC::::::::::::C                    f::::::::::::::::f       ttt:::t                               //
//    D:::::::::::::::DD      CC:::::::::::::::C                   f::::::::::::::::::f      t:::::t                               //
//    DDD:::::DDDDD:::::D    C:::::CCCCCCCC::::C                   f::::::fffffff:::::f      t:::::t                               //
//      D:::::D    D:::::D  C:::::C       CCCCCCnnnn  nnnnnnnn     f:::::f       ffffffttttttt:::::ttttttt        ssssssssss       //
//      D:::::D     D:::::DC:::::C              n:::nn::::::::nn   f:::::f             t:::::::::::::::::t      ss::::::::::s      //
//      D:::::D     D:::::DC:::::C              n::::::::::::::nn f:::::::ffffff       t:::::::::::::::::t    ss:::::::::::::s     //
//      D:::::D     D:::::DC:::::C              nn:::::::::::::::nf::::::::::::f       tttttt:::::::tttttt    s::::::ssss:::::s    //
//      D:::::D     D:::::DC:::::C                n:::::nnnn:::::nf::::::::::::f             t:::::t           s:::::s  ssssss     //
//      D:::::D     D:::::DC:::::C                n::::n    n::::nf:::::::ffffff             t:::::t             s::::::s          //
//      D:::::D     D:::::DC:::::C                n::::n    n::::n f:::::f                   t:::::t                s::::::s       //
//      D:::::D    D:::::D  C:::::C       CCCCCC  n::::n    n::::n f:::::f                   t:::::t    ttttttssssss   s:::::s     //
//    DDD:::::DDDDD:::::D    C:::::CCCCCCCC::::C  n::::n    n::::nf:::::::f                  t::::::tttt:::::ts:::::ssss::::::s    //
//    D:::::::::::::::DD      CC:::::::::::::::C  n::::n    n::::nf:::::::f                  tt::::::::::::::ts::::::::::::::s     //
//    D::::::::::::DDD          CCC::::::::::::C  n::::n    n::::nf:::::::f                    tt:::::::::::tt s:::::::::::ss      //
//    DDDDDDDDDDDDD                CCCCCCCCCCCCC  nnnnnn    nnnnnnfffffffff                      ttttttttttt    sssssssssss        //
//                                                                                                                                 //
//                                                                                                                                 //
//                                                                                                                                 //
//                                                                                                                                 //
//                                                                                                                                 //
//                                                                                                                                 //
//                                                                                                                                 //
//                                                                                                                                 //
//                                                                                                                                 //
//                                                                                                                                 //
//                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DC is ERC721Creator {
    constructor() ERC721Creator("DCnfts", "DC") {}
}