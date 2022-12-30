// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Metis’s Children
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMHHMMMMMMMMMMMMMMmM#MMMMMM    //
//    MMNMMNMNMMMMNMMNMMNMMNMNMMNMNMMNMMNMMMMMNNMNMMMMNMMMMNMMMMMMNMMNMMNMMNMMNMMMMHMMMNMMMMMMMMMHM#[email protected]    //
//    [email protected]@[email protected]@[email protected]#[email protected]    //
//    [email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@HMMMMMMNMNMMMNMMNNMMMMMNMMMNMMMMMNMqMHM#@MM    //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@HNHMk    //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@[email protected]@@[email protected]@@@[email protected]    //
//    [email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]#MMMMqM    //
//    [email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@MHNHM    //
//    [email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@@[email protected]@@[email protected]@[email protected]@MHNHH    //
//    [email protected]@@[email protected]@@#@[email protected]@[email protected]@[email protected]@@[email protected]@@[email protected]@@@[email protected]@@@@@[email protected]@[email protected]    //
//    [email protected]@[email protected]@@[email protected]@@[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]#[email protected]#HHHq    //
//    [email protected]@[email protected]@@[email protected]@@[email protected]@[email protected]@[email protected]@@@[email protected]@[email protected]#[email protected]    //
//    [email protected]@@@[email protected]@[email protected]#[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]#MM#[email protected]    //
//    [email protected]@@[email protected]@[email protected]@@[email protected]@[email protected]@@[email protected]@[email protected]@HM#[email protected]@    //
//    [email protected]@[email protected]@H#M#[email protected]#[email protected]@[email protected]@@[email protected]@HMMMqqMgmqmMHmHmmmqqqmMMmgmmgMMHMMMHHMMM#MNMMHMM#@[email protected]    //
//    [email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]    //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@#@@@    //
//    [email protected]@@[email protected]@[email protected]#[email protected]@M#[email protected]@    //
//    [email protected]@[email protected][email protected]@[email protected]@[email protected]@[email protected]    //
//    [email protected]@[email protected]@@[email protected][email protected]@[email protected]@[email protected]@[email protected]    //
//    [email protected]@[email protected]@H#rdMOtOllllzl==vTx.([email protected]@[email protected]    //
//    [email protected]@[email protected]@@[email protected]@H#rd#ktttllll=z!..?c.>7_..JTQgMNMNMMMM#M#[email protected]@[email protected]@[email protected]#MMNHbSz    //
//    [email protected]@[email protected]@HH#@H#rrMKttOllz=v~..../d..`.([email protected]#[email protected]@MMkQ    //
//    #[email protected]@@@#[email protected]@@[email protected]#wQd#9V9Zlzv_...`..%.`?([email protected]@@@MM9TM,[email protected]@MMMkWuuzu    //
//    [email protected]#@[email protected]#MM#0rdNkyzll>......`<`. (9?`` T6(H#9=_....(WNqNqqqqqMmN_([email protected]@MMqHSuuXuu    //
//    [email protected]@@HM#MMNvXvWyOOl!....``...`..`.` .?"!_..`..`..`[email protected]    //
//    MMqH#@@@@[email protected]@HKZMMXAmQNQgaJJ_.`..``..``..`.`...`..`..`[email protected]    //
//    [email protected]@[email protected]@vdNNMNMMMMMMMN/..`.``.`.``...``.``..``..``..-NMHkqqqqMMMHHmmHNMMmmMmHMMMNHHZuuuuXQkM    //
//    [email protected]@@@HM'` .`..`.`.`.`..`..`.`..`......WHMqqqqqMMMNMmmmMMHmqMHmHMMHHHMMmMMMNMM    //
//    HWWWWHWWyVWWkyyRdM#Ms#M"[email protected]@B!...>`.`.`..`.```..``.`.`..`.`[email protected]    //
//    qyyyXHyWWZZZWkykkmHMTmuHMB^...`.`.`.`.``.`..``.`..``.`..`....-MHHHqqqHMHqMHqmHNMqHmMmmmHMNHMMMMMNMMM    //
//    HVrwWWyZKXZZZWkWXMMmtZY!...........`.`.`..``..`.`....`..`[email protected]@[email protected]@@@    //
//    [email protected]/........`.`..`..`.`.`.`.`.`.``..`[email protected]@gggMMM    //
//    dwXWXIXXXZZkZZyWMMMMMM-....._`.(gNMNY^..`..`...`....`........_(MNHNMmmHqHMHMNHHHqqHNHNmqmqMMHHHMMNMM    //
//    dHUtOtOWZWrZWWkQmNMMNNa-..._(MMMY-..``..`.`..`..`..`.......-JdMMMHMHMmMHqMMHqHHMMBNHNMHqqqmHqMMMMNMM    //
//    [email protected](@MM$.......~..`..`............([email protected]`,MHMMNHqmHMNNHMMMM    //
//    [email protected]@[email protected]@...```...`..-=(,...`...`.(+udMElOWMHMHNHNHM="YHB=(%<`WHHMNMNHmmmMMNHHM    //
//    [email protected]@@@MMHMMMMMH%......`.`..=.JCWde....-(jgMNMHZlzdHHHNH#?NHNz?=>`.z=_,MHHHMNHMMNNHHHHH    //
//    [email protected]@[email protected]@@@@[email protected]#__...`..`.-!.kI<+Wd[.([email protected]?=:`J1?>`[email protected]    //
//    #MM##MMMMMHH#[email protected]@[email protected]@@[email protected]`..(!.jHz>>+8dgMMMMMMH9lzv?1d#1=?=WHMmMMNz~`-+??-,NWNkHqkHMMHMMMH    //
//    MM#NMMmMHMH#[email protected]@[email protected]@m,(^`[email protected]<jC??JMMNMMH8l==v_..-Wz???1TMMNMMN_`(<=?<.MbHHkHHqqHqmqmq    //
//    [email protected]@@MMgMHNqHMMHHMHHMMMmqqqqMHHMMMMMHM^```?WuD+???dMMH9IOlv<.....(b?+?1=zWMMHHN.,{+?+<JHWNbkHHkkqqkHM    //
//    @[email protected]@MMMNqkqqHHMMMHMMB>````` 4x+1??d#UOv=lz!......-Wz<>??==vHHMNH([<??=d#WMHkbHMHkqqqM    //
//    [email protected]@[email protected]>>~```````XyuaadNOll==~......1.?b<>???1=??HHNWh.zz?JFT-.?7UHHMkkqq    //
//    [email protected]??>;;<..`````(N>???1Tmz=z...`.`.(..vag&z??+??1?TMNWkvTT91++wY```?MMNM    //
//    [email protected]@MMHNkWMHkWHMHkHHH#?>1+;;;+..JV^(X???++??Ts=-...`..(_..?S=zTBWXAaduVHMHWa.``````````.WHM    //
//    [email protected]@@@@@@@[email protected]<<;jM#Y+J=`` <XzTQxz1z>?hz-.`..`,<...(1z=====<<1==vMMHWh,1.``.`.``.Wq    //
//    [email protected]@gM#[email protected];;;<X/_`````.<K;>+?TkdTz>4c+-.`..[.`..._<?<+-_..(=vJ?THVyWN.+```.``,N    //
//    [email protected]@ggM8=ll====1=z<WpWMD><!` (+`````(d>>;>;+x<7I<<HZY9O-.3.`.`(J"=!....-ugZ!`` TWVHHHHm,.``,H    //
//    zZ#HpWBXWWWHMkll=zl====?<(HHH#;<`````.n`` .J3;;;jv=<<;;;;d_..`.?l`.`.?..`....`(+vH,```(xWHNHkWpWNa-g    //
//    =uMNBlzyyyyyKOz===1===d>.MWMHC` `  ` ` G `J<:++V1< ` ~~! (l`.``.`..`.`.`..`.. <<<<?h.`` 4JM#HWHHHmgM    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MC is ERC721Creator {
    constructor() ERC721Creator(unicode"Metis’s Children", "MC") {}
}