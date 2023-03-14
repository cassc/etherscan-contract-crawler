// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ODD OMENS by HIDDEN ONES
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                          `-:/osyhhdddddddhyso+:-`                                          //
//                                     ./ohmNNMMMMMMMMMMMMMMMMMMMMNNmho/-                                     //
//                                 ./ymNMMMMMMMMNmdhhyyyyyyhhdmNMMMMMMMMNmy+-                                 //
//                              -odNMMMMMMmhso+++osyyh/..:hhysoo++oshmMMMMMMNdo-                              //
//                           .+dNMMMMMdy++oydmNNMMMMMs-mm:oMMMMMMNmdyo++sdNMMMMNd+.                           //
//                         -smMMMMNho/ohmNMMMMMMMMMM+:mMMN//NMMMMMMMMMNmho/ohNMMMMNs-                         //
//                       .sNMMMMmo/odNMMMMMMMMMMMMN//NMMMMN+:NMMMMMMMMMMMMNdo/odMMMMNy-                       //
//                     `oNMMMMd+../oydNMMMMMMMMMMN:+NMMMMMMMo-mMMMMMMMMMMNdhs/..+hMMMMNs.                     //
//                    :mMMMMd//h+:mdys++oydmNMMMm-oMMMMMMMMMMs-dMMMNmdyo++oydm+:d//dMMMMm/                    //
//                  `sNMMMNo:hMMd`NMMMMNmhso+osy.oMMMMMMMMMMMMy.yso+oshmNMMMMM.yMMh/+NMMMMs`                  //
//                 .hMMMMd:oNMMMM.yMMMMMMMMMMm+`+++oydmNMmdys+++./mNMMMMMMMMMh`NMMMNs:hMMMMd.                 //
//                .dMMMMs-hMMMMMM+:MMMMMMMMMMy-dMMNhs:.//-:ohNMMm-sMMMMMMMMMM+/MMMMMMd-oMMMMm.                //
//               `dMMMMo-mMMMMMMMd`NMMMMMMMMo-dmhs++oshmmhso++shmd:+NMMMMMMMN`hMMMMMMMN:+MMMMm.               //
//              `hMMMMo-NMMMMMMMMM.yMMMMNNd+`/+oydmMMMMMMMMMMNdyo+/`/dmNMMMMh`NMMMMMMMMN:+MMMMd`              //
//              oMMMMy.mMMMMMMMMMMo:mhso+/`/dNMMMMMMMMMMMMMMMMMMMMNm+ /++shm//MMMMMMMMMMN-sMMMMs              //
//             .NMMMm`hMMMMMMMNmhs/ /shmm:+MMMMMMMMMMMMMMMMMMMMMMMMMMs-mmds+ :oymNNMMMMMMm`dMMMM-             //
//             yMMMM//MMNNdyo/+oydN-sMMm-sMMMMMMMMMMMMMMMMMMMMMMMMMMMMy.dMMy.Ndyo+/+ydNNMMo-MMMMh             //
//            `MMMMm ss+/+shmMMMMMMs-Md.yMMMMMMMMMNNdhyyyyhdNNMMMMMMMMMh.hM/+MMMMMMmhs+/+sy hMMMM.            //
//            +MMMMo +dNMMMMMMMMMMMm s.dMMMMMMMNy+-`:ohhhhs:`./smMMMMMMMd.s`dMMMMMMMMMMMNdo /MMMMo            //
//            yMMMM-/.hMMMMMMMMMMMMM..mMMMMMMd/:y/-dMMMd/ohMm::y//hMMMMMMm-`MMMMMMMMMMMMMd./.MMMMh            //
//            dMMMM`hd.yMMMMMMMMMMMo`-MMMMMN/:dMs.NMMMMM/  :NM-oMm/:mMMMMM:`/MMMMMMMMMMMh.dm NMMMm            //
//            dMMMN`dMm-oMMMMMMMMM/:m mMMMM-/MMM/+Md/yho`   hMs-MMM+.NMMMN d/:NMMMMMMMMs.mMN mMMMN            //
//            dMMMM`hMMN:/MMMMMMN:+MM:oMMMMm:/mMs-MM:      -NM:oMm+:mMMMMs.MMo-mMMMMMMo-NMMm NMMMm            //
//            yMMMM-sMMMM/:NMMMm-oMMMy.MMMMMMh//y/:mMh+//+hMm/:y/:yMMMMMM:oMMMy.dMMMM/:NMMMy.MMMMh            //
//            +MMMM+:MMMMMo-mMd.yMMMMN dMMMMMMMms/.`:shddhs/`./smMMMMMMMN mMMMMh.hMN:+MMMMM+/MMMMo            //
//            .MMMMd`mMMMMMs.s.hMMMMMM:+MMMMMMMMMMNmhyssssyhmNMMMMMMMMMMs-MMMMMMd.s-oMMMMMN`hMMMM-            //
//             yMMMM:+MMMMMM/ sMMMMMMMy.MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM-sMMMMMMMy :MMMMMMo-MMMMd             //
//             -MMMMm`dMMMMo-y.yMMMMMMN`dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMm mMMMMMMh.y:+MMMMm`dMMMM:             //
//              oMMMMy.NMM+:NMm-sMMMMMM/+MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMo-MMMMMMy-dMN//NMN-oMMMMy              //
//              `dMMMMo:m//NMMMm:+MMMMMh`MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM-sMMMMMo-mMMMN+:m//MMMMm`              //
//               .mMMMMo.`ossssso`/ossso +sssssssssssssssssssssssssssso +ssso/`+ssssso.`/NMMMm.               //
//                .mMMMMs.smmmmmmm+.hmmm/:mmmmmmmmmmmmmmmmmmmmmmmmmmmm/:mmmd-/dmmmmmmy.oNMMMm-                //
//                 .hMMMMh:sNMMMMMMo-mMMh`NMMMMMMMMMMMMMMMMMMMMMMMMMMM.yMMm:+NMMMMMMy-yMMMMd.                 //
//                  `sMMMMN+:hMMMMMMy-dMM.hMMMMMMMMMMMMMMMMMMMMMMMMMMd`NMm-sMMMMMMd/+mMMMMy`                  //
//                    /mMMMMd//dMMMMMh-hM+/MMMMMMMMMMMMMMMMMMMMMMMMMM+:Md-yMMMMMd+/hMMMMm/                    //
//                     .sNMMMMh//hNMMMd-yh`NMMMMMMMMMMMMMMMMMMMMMMMMM.yy-hMMMNh+/hMMMMNy.                     //
//                       -yNMMMMdo/odNMm-o`yMMMMMMMMMMMMMMMMMMMMMMMMd`o-dMNds/odMMMMNy-                       //
//                         -yNMMMMNh+/ohd:`:MMMMMMMMMMMMMMMMMMMMMMMM+ -hho/+hNMMMMNy-                         //
//                           .+dNMMMMNds+/``dmNMMMMMMMMMMMMMMMMMMNmd.`/+sdNMMMMNmo.                           //
//                              -odNMMMMMNdyo+++osyyhddddddhyyso+++oydNMMMMMNms:`                             //
//                                 -+ymNMMMMMMMNmdhhyyssssyyhhdmNMMMMMMMNmh+-                                 //
//                                    `-/shmNNMMMMMMMMMMMMMMMMMMMMNNNds/-`                                    //
//                                          .-/+oyhddmmmmmmddhys+/:.                                          //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract OddOmens is ERC1155Creator {
    constructor() ERC1155Creator("ODD OMENS by HIDDEN ONES", "OddOmens") {}
}