// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MAcci BOX
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                       //
//                                                                                       //
//    [email protected]#dWXZZZZZXKkXXZZZZZZZZZZZZZZZZZZZMMMMNNx                 //
//    NBO0QMWM81d0dXZZZZZZZZQQMDJZXZZZZZXUWXXw0XkZZkZZZZZZZZZZZZZGTNMMMMN,               //
//    XVqMHNMNdwZXXQQgNNNNdMWM$jNRZZZQKXWHZd000H#ZyNdwZyZZZZZZZZXwXvNWMNdkh              //
//    0dMdMM#MdMMNMMNMMNMNMNMt+NMMRQMMHKdZZZZXQW#ZXMk0XddZZZZZ0ZwwSXwWHNMddN.            //
//    dMNMNMWHMNMNMNMMNMNMMMC(NMMMMNMNduMmkZZKHM#ZXN#XddSXkZZZZdXMdkUk0NNMddm.           //
//    MNMNM##MMMNMMNMMMMMMMD`JMMNNMMNNF(MMMMMHHMNZZMNQZkdkNkZZZ0XdNXkXWXNNNNHk,          //
//    MMMNMHHMH""7`             _"WMMM`dNMNMMXHNMKkMMM#kXkdNkZZZdNMKZkZNZdMK#NH,         //
//    MMMM9=                         ! dMMNM#WHNM#WMMMMWXHWMNZZZdMNNZZZdNyNNMdKH, `      //
//    T"`                               (TMMNMHMMNWdMNNMMMMMMRZXMMMMKKXZMNdM#NNWQ        //
//                     `   `  `            ?MM#MNHNWMNMNNMNMNMKdMNNMNNWyMMNNMMd#Nh       //
//     Ja.                                   (WMMvMNMMMMNMNMMMMMMMNMNMM#MNMMMNNMMM;      //
//      4Kn.  `   `               `            ,WrdMMNNMMNMNMNMMNMMNMMMMMMNMNMMMNMN      //
//       ?Ndo   `    ` `  `  `  `    ` ` .....   `(MMNMMNMMNMNMMNNMMMUMMMMMNMNMNMNM,     //
//        .WMN.                  ...dNMMM9=        zMNMMMNMMNMMMMMNM#ZMMNMNMMNMMNMNb     //
//    .     .T>    `     `    .dmgMM""`             MMM#MMNMNM#MMMMN#ZMNMNMNMMNMMMM#     //
//    . _              `    ` ""!               `   ,MNDMMNMMNN#MMMMHMMMNMMNMMMNMNMN     //
//    MN,~ `-,    `       `            `  `          MM{dMNMNMWH#MNMMMMMNMNMNMMNMMNM     //
//    OHMN&  ~`      `            ._      ....-...   d#~JMMNM#HdNNMNNMNNMNMNM#MMNMM#     //
//    ==vMM,                     !   `.,u&MMMNgJ-.?, .D`(MNMMMW#dMMMNMMNMMNMM#MMMMN#     //
//    ``_MNMx   `  `   `  `  `      .(JMMMMMMMMMm/.,, < .MNMNNMNMNMNMNMMNMMN#XMWMMM]     //
//       dMFM,                    ,(dMMMMD,MMdMNMJ/     .MMNMMMMNMNMNMNMNMNMZZHdWM#      //
//       JMb N.                 `.+M8<MNF .MM=MMMPb(.gD .dMNMMMMMNMMMNMMMMWZZZWHdM'      //
//    ,  ,MN ,]                 .M5!`.MM! MM#=dMNMMMD`  ~JMMNMMNMMNNMMMMZZZZZZXq#!       //
//    +   d8L(N                ,=`   [email protected]`JMM%_zNMMD    ~~JNMMM9""!`  `[email protected]         //
//    ?7j, h>cJ                     .M34vMMF  .#"     .~(MMD` .-777>   (HZykXdF          //
//    . .T5jMK'        `            .v(+<JD   ?3     .~(M"  .6!    ..&c(HWKdD!           //
//    ,--                     `   ..,b_(J~.J?"`      ~?!.ZL 5:     4OAIdN#"`             //
//    <<..`                   `..__~.?77_(<!        _   Sr7 ?   ..,   (@^                //
//    ```         ``             .<?<<..`                 !     ,A7 .J-                  //
//                                 _.__.                     dk%  .(Y?>zC(.              //
//                    `  `  ....v"=JF              ..NNNNNNHUVrwZU3==?+?>>+6,            //
//    ,             UNUY""!`     .-=              .MMNNMMBI=========?====1?>?T,          //
//    ?H,             ?7<<((?777`               .dMNMMM6zllllllll====??=?=?=+>+S,        //
//    >>1TQ,    `                            .(jMMMNMMN;;;;>>+1zll===?==?=??=?>??,       //
//    &x>>+dHJ.                          ..(:+jNeTMMN;>;;;;;>;>+&uggggAAAAaaz>>>>?L      //
//    ZXHMMMMNMN,                 ...v=:::::;jMMMMN+;;;>+j+dT9T7<~~~~~~~~~~<<7z>>>+h     //
//    wddMMMMMMMNMa...  ....JgMMM93:::::::::jMMMMMMMmgTT<~~~~~~~~:~~~~~~~~~~~~~~<>??[    //
//    rddMMMMMMMMMMMMMMMMMMMmV<:(:::+:::((::dMMMM#9=~~~~~~~~~~~~~~~~~~~~~~~~~~~~~:<?d    //
//    rwMMMNMNNMMMMMMM9===uMMb+dN<+MMp:+MP(jEgY=~~~~~~~~~~~~~~~~~~~~~~~~~~~~~:~::~:~<    //
//    trHMMMMMMMNMM#VrI==ldMMMMMMMMMMMNMMNd#=~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~:~~::::~:~    //
//    rtWMNMMMNMMMNIzrOzudMMBdMMMMMMMMMMM5~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~:~:~:::::~~    //
//                                                                                       //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////


contract MAcci is ERC721Creator {
    constructor() ERC721Creator("MAcci BOX", "MAcci") {}
}