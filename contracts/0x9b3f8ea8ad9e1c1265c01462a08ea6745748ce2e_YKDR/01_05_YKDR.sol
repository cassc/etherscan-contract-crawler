// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: yokodori
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM]                                                           JMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM]                                                           JMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM]                                                           JMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM]                                                           JMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                                           MMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                                           MMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                                           MMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                                           MMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMF                                                                                         (MMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMF                                                                                         (MMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMF                                                                                         (MMMMMMM    //
//    MMMMMMMMMMMMMMMY""""""t                                                                                         (MMMMMMM    //
//    MMMMMMMMMMMMMMN_                                                                                                (MMMMMMM    //
//    MMMMMMMMMMMMMMN_                                                                                                (MMMMMMM    //
//    MMMMMMMMMMMMMMN_                                                                                                (MMMMMMM    //
//    MMMMMMMMMMMMMMN_                                                                                                ("""""""    //
//    MMMMMMMMMMMMMMN_                                                                                                            //
//    MMMMMMMMMMMMMMN_                                                                                                            //
//    MMMMMMMMMMMMMMN_                                                                                                            //
//    [email protected]                                                                                                             //
//    MMMMMMM]                                                                                                                    //
//    MMMMMMM]                                                                                                                    //
//    MMMMMMM]                                                                                                                    //
//    MMMMMMM]                                                                                                                    //
//    MMMMMMM]                                                                                                                    //
//    MMMMMMM]                                                                                                                    //
//    MMMMMMM]                                                                                                                    //
//                                  MMMMMMMMMMMMMMMMMMMMMM]      `(;;;;;;dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN>;;;;;;~           //
//                                  MMMMMMMMMMMMMMMMMMMMMMF       ;;;;;;;dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN>;;;;;;~           //
//                                  MMMMMMMMMMMMMMMMMMMMMMF       ;;;;;;;dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN>;;;;;;~           //
//                                  MMMMMMMMMMMMMMMMMMMMMMF      `<;;>;>;dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc>;>>;>_           //
//                                  MMMMMMM]       MMMMMMMF       MMMMMMMb~~~~~~(MMMMMMMF              .;;;;;;jMMMMMMMMMMMMMMM    //
//                                  MMMMMMM]       MMMMMMMF       MMMMMMMb~~~~~~(MMMMMMMF              .;;;;;;+MMMMMMMMMMMMMMM    //
//                                  MMMMMMM]       MMMMMMMF       MMMMMMMb~~~~~~(MMMMMMMF              .;;;;;;+MMMMMMMMMMMMMMM    //
//                                  MMMMMMM]       MMMMMMMF       MMMMMMMD~~~~~~(MMMMMMMF              .<<<<<<+MMMMMMMMMMMMMMM    //
//                                  MMMMMMMb;;;;;;<                              MMMMMMMF                             (MMMMMMM    //
//                                  MMMMMMMb;;;;;;<                              MMMMMMMF                             (MMMMMMM    //
//                                  MMMMMMMb;;;;;;<                              MMMMMMMF                             (MMMMMMM    //
//    ...............               MMMMMMMb+++++++........                      MMMMMMM$                      .......(MMMMMMM    //
//    MMMMMMMMMMMMMMN_              [email protected];;>;;>;                                             MMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMN_             `[email protected];;;;;;;                                             MMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMN_              [email protected];;;;;;;                                             MMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMNJ..............gggggggdMMMMMMMHHHHHHHh++++++J.......                              ........MMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN>~~~~~~JMMMMMMM<~~~~~~_                             JMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN>~~~~~~JMMMMMMM<~~~~~~_                             JMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN>~~~~~~JMMMMMMM<~~~:~~_                             JMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMB"""""""!``````?""""""Yggggggg,       (JJJJJJJJJJJJJJJJJJJJJ+MMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM]               ~~~~~~(MMMMMMM]       MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM]               ~~~~~~(MMMMMMM]       MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM]               ~~~~~~(MMMMMMM]       MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM=777777'       ggggggge~~~~~~_7777777'       ?777777UMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM               MMMMMMMb~~:~~:~                      (MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM               MMMMMMMb~~~~~~~                      (MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM               MMMMMMMb~~~~~~~                      (MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM               UHHHHHHWwwwwwwwNNNNNNNR((((((_        ~~~~~~?MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM               dyyyyVyVVVVVVVfMMMMMMMb;;;;;;<               MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM               dVyVVyyVyyyyyVVMMMMMMMb;;;;;;<               MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM               dVyVyVVyVVyVyyfMMMMMMMb;;;;;;<               MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM]       dyVyVyyVyVVyVVW<<<<<<<dMMMMMMN_      (MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM]       dVyVyVyVyyVyVyW~~~~~~~gMMMMMMN_      (MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM]       dVyVyVVyVyVyyVW~~~~~~~gMMMMMMN_      (MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM]       dVyyVyyVyVyVyyW~~~~~~~gMMMMMMN_      (MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract YKDR is ERC1155Creator {
    constructor() ERC1155Creator() {}
}