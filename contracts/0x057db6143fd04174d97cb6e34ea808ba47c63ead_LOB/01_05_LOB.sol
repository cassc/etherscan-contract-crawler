// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LoopableBalloon
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    NNMNNMNNMNMNNMNNMNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMNNMN    //
//    Thanks to dear NyanBalloon and this time our friends nouns,mfers,wolfgame,pepe,cryptoadz,rektguy,xcopy.For the culture!MNNMNNMNNMNMNNMNMNMNNMNNMNNMNMNNMNMNMNNMNNMNNMNMNNMNMNMNNMNNMNNMNMNNMNMNMNNMNNMMN    //
//    NNMNNMMNMNMNNMNNMNMNNMNMNNNMNMNNMNNMNNMNMNNMNMNMNNMNNMNNMNMNNMNMNMNNMNNMNNMNMNNMNMNMNNMNNMNNMNMNNMNMNMNNMNNMNNMNMNNMNMNMNNMNNMNNMNMNNMNMNMNNMNNMNNMNMNNMNMNMNNMNNMNNMNMNNMNMNMNNMNNMNNMNMNNMNMNMNNMNNMMN    //
//    MNNMNNMNMNMMNMNMNNMNMMNNMNMNNMMNNMNNMMNMNMNNMNNMMNNMNNMMNMNMNNMNNMMNNMNNMMNMNMNNMNNMMNNMNNMMNMNMNNMNNMMNNMNNMMNMNMNNMNNMMNNMNNMMNMNMNNMNNMMNNMNNMMNMNMNNMNNMMNNMNNMMNMNMNNMNNMMNNMNNMMNMNMNNMNNMMNNMNNMN    //
//    NMNMNMNNMNNMNNMNMNMNNMNMNMNMNNMNMNMNMNNMNNMNMNMNNMNMMNNMNNMNMNMNMNNMNMMNNMNNMNMNMNMNNMNMMNNMNNMNMNMNMNNMNMMNNMNNMNMNMNMNNMNMMNNMNNMNMNMNMNNMNMMNNMNNMNMNMNMNNMNMMNNMNNMNMNMNMNNMNMMNNMNNMNMNMNMNNMNMNMNM    //
//    NMNNMNMNMNMNMMNNMNMNMNMNMNMNMNNMNMNMNNMNMNMNNMNNMNMNNMNNMNNMNMNNMNMNMNNMNNMNNMNMNNMNMNMNNMNNMNNMNMNNMNMNMNNMNNMNNMNMNNMNMNMNNMNNMNNMNMNNMNMNMNNMNNMNNMNMNNMNMNMNNMNNMNNMNMNNMNMNMNNMNNMNNMNMNNMNMNMNMNNM    //
//    MNMNNMNMMNMNNMNMNMNMMNMMMMMMMMMMNMNNMMNNMNNMNMNMMNMMNMMMMMMMNMMMNMNNMNMNMMNMNNMMNMMMNMMNMMMMNMNNMNNMNMNNMNMNMMMMMNMMNMMMNMMNNMMNMNMNNMNMNNMNMMMMMMMMMNNMNMNNMNNMNMMNMNMNNMNMNMNMMNMMMMMMNMNNMNNMNNMNNMNN    //
//    NMNMNMNNMNMMNNMNNMMNM9! ._~..-.?YMMNNMNMNMNMMNMMNMM5<_______?TMNMNMMNMNNMNMNMMMM9=_-... _"WMNMMNMNMNNMNMNMNMMNMM9XwwwzzVHMMNMNNMNMNMNNMNMMNMMB0O&+vZTMMNMNMNMNMNNNMNNMNMNNMNMNMMHYT<<7TWMMMMNMMNMNNMNMMN    //
//    NNMNMNMNMNNMNMNMNMM^ [email protected]~_(;;;;;;;;:__?MMMNMNNMNNMMNB!-~~~~~~~~~...7MMMNMNMNNMNNMMN#SwXWWWyyyXXwOvHMMNNMNNMMNNMMM8wzzuzzzwrOz+TMMMMNNMNMNNMNMNMMNMMMB>;;>;;;;:___TMMNMNNMMNMNNM    //
//    MNNMNNMNMNMNMNMNMF ..~~~~~~~~~~~~~~_HMNMNNMNMMM=_(;;;;;;;;;;;;;:_dNMNMNMMNMM^-~~~~~~~~~~~~~~.-UNMNMNMNMNMMMSwyWpppppfffVyXXw?MMMNMNNMMMMSwuuZZuuuuuuzvOO+dMMMNNMNMMNMNMNNMNB;>>>>>>>>>>;;:__dMMNMNNMNNMN    //
//    NMNMNMNNMNMMNMMMD`..~~~~~~~~~~~~~~~~~WMNMMNNMM^_(:;;;<:;;;;;;;;;;_?MMNNMNMM!.~~~~_~~~~~~~~~~~~.UMMNMNMMMNMXXyWfWWWppppppffyXXvMMNMNNMN#OzuuXuZZZZZuuuuuwOz?MMNMNNMNNNMNMMM5>>>>????>>>>>>;;:_(MMNMNNMNMN    //
//    NMNNMNMNMNNMNNN#``_~~~~~~~~~~~~___~~~(MMNNMNM$-(::;;;;;;;;;;<<;;;;<dNMNMMN%-~~~~~~~~~~~~__~~~~~.MMNNMNNMM6XyfffWXfVVVfWpppfVyXvNMNMMNMOzXuuXwuuuuuZZZuuuzrzJMNNMNNMMNNMNMD>>><>>>>>>?>>>>>;;:_(MMMMNNMNM    //
//    MNMNNMNMMNMNMMN] -~~~~~~~~~~~~~_._~~~~dMMNMNN_(::<>;;;;;;:::_(;;;;;?MNMNM# ~~~~~~~~~~~~~ .~~~~~~(NMNNMMN#duXffpWVVyyyS([email protected],uZZuuuzOzMNMNMNNMNMNM#<+???>>;;><(>?>>>>;;:~dMNNMNMNN    //
//    NMNMNNMNNMNMNMM[ ~~~::~:~~~~~_`~~~~~~~JMNMNM#-(;<?>>>>;;::~(;;;;;;;+NMNMNF-~::::~~~~~._-~~~~~~~~([email protected]MNNMNMN#+?==??>>;(;>>>?>>>>;;_JMNMNMNMN    //
//    NNMNMNNMMNMNNNMb ~~::::::::~~~.~~~~~~_MMNNMNM/(>>??<??>>;;_(;;;;;;;(MNNMMN-:::::;::~~_-~~~~~~~~~(NNMNNMMNwypbbkbpVykJyVVWppWfW0dNMNMNbuyyyyyZuX&zuuuuZZuuuwIdNNMNMMNNMNM#1l====?<-<>>>>?>>>>;;~(MMNNMNNM    //
//    MNMNMMNNMNMMNMNN/_:::;;<::::~~~~~~~~~(MMNMNNMb(>??=?+???>;;;;;;;;;<MNNMNMMb~::;<<;::::~~~~~~~~~(MMMNNMNNMmyWbWWkbppfffVWffffVWGMMNNMMNwXyXVVyyZZZuuuuuuuuzOuMNMNNNMNMNNMMxlzll===?????>>>>>>;:_dNMNMNMNN    //
//    NMNNNMNMNNMNNMMNN._:::;;;::::~:~~~~~(MMNMNMNNMp<>??====???>>;>;;;<jMNMNMNNM/:;;;;;;;::::~~~~~~_JMNMNMNMMNNwyWkkkqkkbbpppffffy0MNMNMNNMNXXVVVVyyyZyZZZuuZuvIMMNNMMNNMNMMNMN1lttlll====???>>>;;<(MMNNMNNMM    //
//    NMNMNNMNMNMNMNNMNN,~:;;;;;;:::~~~~~(MNNNNMNMMMNp<+?=====???>>;;;;jMNMNNMNMMN,:;;;>;;;::::~~~~_(MNNNMNMNNMMNXWWkkkqkkkpbfffWy0dNMNMNNMMNNXyVVVVVyyZyZZuuuwOdMNMNNMNMNNMNMMNNllttllll==???>>>;<(MNNMNNMNNM    //
//    MNMNMNMNMNMMNMNMNMN,_:;;;;;::::~~~(MMNMMNNMNNMMNR<+=====???>;;<(dNNMNMNNMNNMMe:;;;;;;:::~~~_-dMNMMNNMNMNNMMNkWpbkkkkkbfffWZXMMNMNNMNMNMNNXyVVVVVyyZuZuXOzMMNMNMNNMNMNNMNNMMNzttttlll=???<;;<(NMNMNMMNMNN    //
//    NNMNNMNMNMNNMNMNMMMMN,~:;;;:::~~(MMMNMNNMNNMNNNMMMJ<??==???>;<(MMNMNNMMNMNMNMMNJ<;;;;;::~_.(MNMNNMNMNNMNNMNMNNXWpbkbbpVV0zgMNNMNMNMNNMNMMMKXyyyyyyuuXwvqMNNMNNMMNNMNMNNMNNMMMmlttlll=??<;<(dMMNMNNMNNMNM    //
//    NMNMNMNNMNMNNMNNNNNNMMNJ<::::_(MMNNMNNMNMMNMNMNNMNMNJ>????>+(MNMNNMNMNNMNMNMNNMMNJ;;;::~_(MMNMNMNNMNMNNMMNNMMNMmyWWppVX0gMMNNMNNMNNMNNMNNMMNmUWyyZZVvqMMMNMNNMNNMNMNMMNMNMNMNMNezlll=?<<(+MNNNMNNMNNMNMN    //
//    MNMNMNMNMNMMNMNMMNMNMNMMMM3dMMMNMMNNMNNMNNMNMNMNNMNMMMNK(NMMMNMNNMNMNNMNNNMNNMNMNMMap(gMMMMNMNNMNMNNMMNNMNNNMMNMMNgmQgNNMMNMNMNMNMNMMNNMNNNMMMNgyQggMMNMNMNMNMNMNMNNNMNNMNNNMNMMNaec1&+MMNMMNMNMNMNMNMNN    //
//    　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　    M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　       　M                                                                                                 //
//    　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　    M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　　　   M                                                                                                   //
//    　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　    M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　       　M                                                                                                  //
//    　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　    M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　　　   M                                                                                                   //
//    　　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　    M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　       　M                                                                                                //
//    　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　    M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　　　   M                                                                                                   //
//    　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　    M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　       　M                                                                                                 //
//    　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　    M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　　　   M                                                                                                   //
//    　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　    M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　       　M                                                                                                 //
//    　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　    M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　　　   M                                                                                                   //
//    　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　    M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　       　M                                                                                                  //
//    　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　    M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　　　   M                                                                                                   //
//    　　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　    M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　       　M                                                                                                //
//    　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　    M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　　　   M                                                                                                   //
//    　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　　    M　　　　　　　　　　　　　　　M　　　　　　　　　　　　　　       　M                                                                                                 //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LOB is ERC1155Creator {
    constructor() ERC1155Creator("LoopableBalloon", "LOB") {}
}