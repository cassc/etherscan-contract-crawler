// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Atelier K.K.Y.G(一点)
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                          //
//                                                                                                          //
//                                       .+MMMMgJJi./                                                       //
//                                     .MMMMMMMMMNMM8(NMN,  _.                                              //
//                                   .MMMMMMMMMMMNMQMMMMMM,   ~.                                            //
//                                  .MMMMMMMMMM#MMMMMMMMMMM,   .,                                           //
//                                 .MMMMMMMMMMMMMMMMMMMMMMMMN,u.,                                           //
//          `  `  `  `  `  `  `   .MMNMMMMMMMMM#MMMMMMMMMMMMMMdhm.   `  `  `  `  `  `  `  `  `  `  `  `     //
//                               .MMMMMMMMMMMMMdMMMMMMMMMMMMMMMMM/|                                         //
//       `                      .MMMMMMMMMMMMMNMMMMMMMMMMMMMMMMMMNj                                         //
//                              MMMMMMMBWMMMMMMMMMHYH#jMMMMMMMMMMM[]                                        //
//           `   `   `   `     (EMNMMMN>.MMMMMMF7?dMMMn.~"MMMMMMMMN+.   `   `   `   `   `   `   `   `       //
//                           .WNMMMMMMN-qMMMMMMt..dM$    WgJ5MMMMMMbb                                  `    //
//        `                 .4MMMMMMMMMKdMMMMMM-. _?     dMWNMMMMM#MNp                                      //
//            `  `  `  `   .bMMMMMMMM##NdMMMMMMP!/'.!   <v_JMMMMWMF. Th    `  `  `  `  `  `  `  `  `        //
//                         MMSMMMMMMMddMMMMMMMNN!2^    ..<,MMMMM-M]                                   `     //
//       `                .M5dM#MMMMM#MMMMMMM9MMe .?`.  .JuMMM##.#F                                         //
//                        JM+MM6MMMMMMMUMMMMMwMMMm,  ..dM#J#MM#F,#]                                         //
//    NJ.                .MMNMMMM9YUMMN(MMMMM]dMM9N3HMNMNNDNdM#QK#$                                         //
//    MMMN,              Jma&ZWNNNNJMMMMMMMMMb..N?h dVTMMmTNMMMMNFZ                                         //
//    MMMMMMa.          (8>>>?TSg7M#MMMMMMMMNMJkHMMb.Ngx7MNgHWMMM]P                                         //
//    MMMMMMMMNJ.       #?>c>>+>+MMNMMMBWMMMMMNqMNmN1(MMMNg?HNdMMb"~...                                     //
//    MMMMMMMMMMMN,    .Me>m>>Jp>JMMMgMMMMMMMMMNMMMMM^n.J4MM#QdMg<?!`.`i                                    //
//    MMMMMMMMMMMMMMa,  MMMN+>>dNxdMMNNNMMMkMMMNN/TMNh  ."/[email protected]> ., Z?i                                 //
//    MMMMMMMMMMMMMMMMNJ(MMMNm><?HMNMMMMMMMMMMMMNN,zMNb    WNd5.,8. / ,._d#~                                //
//    MMMMMMMMMMMMMMMMMMMMMM8gN6>>>dMNMMMMMMMMMMMMMNNMHb    M]   .(7<JNdNJ=k,                               //
//    [email protected]>>>>??7MMkMMMMMMMMMNMMMNMgggJ(`(   ??(?E>NgbMP                               //
//    MMMMMMMMMMMMMMMMMMMMMMqMC>>jugggg&MMdMMMMMMMMMMMMMNM5>T(.~_.5(NND>dMMM>                               //
//    MMMMMMMMMMMMMMMMMMMMMbMMz+dBBYYM5>+u&uTTMH6>+T5<>+KTx>>>?,.NMMMM$>qdME                                //
//    MMMMMMMMMMMMMMMMMMMMMRMMBagMBg#1+dM3ugM5>>>>>>>>u9>>?Z>>>?dMMMNMI>dNM]                                //
//    [email protected]>uqM1jM3>>>>>>>>+d3>>>uN>>>>dMMMMMI>MMNk.                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMDjE>uMM1>+>>>>>>??ug5>>>juMNgx>+MMMMMMz>MMdN!                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMR>jgM#1>>>>+uV1ugM5+ugNMMMMMSZWdMMMMMMz>MNMr                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMI>>>[email protected]                                 //
//    MMMMMMMMMMMMMMMMMMMMMMMMM#MMMMMb>jdMMMMMMMMMMMMMMMMMMMMMMgMMMMMMzjM#                                  //
//    MMMMMMMMMMMMMMMMMMMMMMMMMNMMMMMMNMMMMMMMNMMMMNdMMNMMMMMNT#MMSvMM>[email protected]                                   //
//    MMMMMMMMMMMMMMMMMMMMMM5-UMMMMMMMMMMMMMbMMKMMMMNMMNMMMmmM[,MMNZwd>z                                    //
//    MMMMMMMMMMMMMMMMMMMMMMMK1&dQMMMMMMMMMMbJMMcMMMMdMNMHqmmmN..HNe=M>r                                    //
//    MMMMMMMMMMMMMMMMMMMMMMMMgMmmmMMNmVMMMMbjMMNJMMMNMMMMHmmN#  HMMNM>%                                    //
//    [email protected]#MMNMgNM: ; OMMM>\                                    //
//    MMMMMMMMMMMMMMMMMMMMMMNMMN#5>>>>>>>JMMbM#dM#JMb?NMMMMNMMMhdMNMMM+}                                    //
//    MMMMMMMMMMMMMMMMMMMMMMBdM#d1>>>>>>>>HMNMD>MNJM$>ddMMMMdMM9GJ<MMMj!                                    //
//    MMMMMMMMMMMMMMMMMMMM6>uMMMMx>?>>?>>>JMM#>>JMdMC>J#NHNk7"4T.(1MMMda,                                   //
//    MMMMMMMMMMMMMMMMM#3>jgMMMMMNx>>>>?>>>MM6>>jMNM<>jNN\/?~JjuJqFdMNdMMN,                                 //
//    MMMMMMMMMMMMMM#6>juMMMMMSMMMNx>ug6>++dE>>+MMM#>>dMM]l..ugMM].bMNkNMMMMm,                              //
//    MMMMMMMMMMMB3jugMMMMMMMNMMMMMMgMNMMMWE>>>[email protected]>[email protected]                           //
//    MMMMMMMMMNgNMMMMMMMMMMMMMHMM#MMMMMM#C>>>uMMMMD>jMNMMMNJMMMMMN.MMPdKMMMMMMMMN,.                        //
//    MNMMMMMMMMMMMMMMMMMMMMgM8dMMMMMMMM8>>>jgMMMMM1>dMdMMM8MMMMMMM|MMN?WMMMMMMMMMMMN,                      //
//    dMMMMMMMMMMMMMMMMMMNMMMNMMMMMMMM8>>>+gMMMMMM#>jM#[email protected],                   //
//    MMMMMMMMMMMMMMBWgMMMMMMMMMMMMM5>>>?uMMMMMMMM$>dMNMMMMMMMMMMWF-MMMN+OMMNJMMMMMMMMMMMNJ.                //
//    MMMMMMMMMMB3ugMMMMMMMMMMMMMM6>>>?uMMMMMMMMM#>jMMdMMMMMMMMM#MPM#MMMN>4MMMNJMMMMMMMMMMMMN,              //
//    MMMMMM#Y>ugMMMMMMMMMMMMMMH6>>>>uMMMMMMMMMMM1uMM#[email protected]           //
//                                                                                                          //
//                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AOZI is ERC721Creator {
    constructor() ERC721Creator(unicode"Atelier K.K.Y.G(一点)", "AOZI") {}
}