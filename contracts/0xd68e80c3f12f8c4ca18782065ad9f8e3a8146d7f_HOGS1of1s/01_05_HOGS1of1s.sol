// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HOGS ONE OF ONEs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//    WMMWMMMWMMWWMMWMMMMMMMM###*zccuxj/\\\/fjxcz***#MMMMMMWWMWn?1xMWMMWMWWMMMWWMMMMMMMMMMMMMMMM    //
//    WMMMWWMWMWWMMMMMMMMMMMMMM##*zcvnxrjjjrxxnuvccz**MMMWMMMMWMc}_]f*MMMMMMMMWMMMMMMMMMMMMMMMMM    //
//    MMMMMWMMMWMMMWMWWMWMWMMMMM###*zvnxrrxxnuuvvcczz*#MMMMMMWMMW#{+++[(tuMMMWWMMMMMMMMMMMMMMMMM    //
//    WMWMMWMWWMMWMMWMMMMMMWMMMMM##*zcunxrrxnuuuvvccz*#MMMMMMMMMMMM\~~~~~~+[|tn*MMMMMMMMMMMWMMMM    //
//    MWWMMMMMMMWMMMMWWMMMMMWWMMM##zzcurjfjrnnnuuuvcz**#######MMMMMM|~~<<<<<<<~~+](fxv*M*zMMMMMM    //
//    MWMMWWMMMMWMWWMMMMMMMMMMMMM##*cujt\|//fjrxxuvccz*****#######M##/~<<<><><<<<<<~~~~~~~~_-??-    //
//    WMMMWMMWWMWMMWMMMMMMMMMMMM#****zcvurftttttfjnnucczz*******#***z*t<<>>>>>>>><<><<<<<<<<<<<<    //
//    WMMWWWMMWMMMWMWMWMMMMMMMM###***###M##*zcuxrjjrxnuvcczz*zzzzzzzccv)<<>>>>>>>>>>>>>>>>>>>>>>    //
//    MWMWMMMMMMWMMMMMMMMMMMMMMMMMMMMM#MMMMMMM##*zvunnuuuvccccvvvvvvvvvn+<<>>>>>>>>>>>>>>>>>>>>>    //
//    WWWMMMMMWWMMWMMMMMMMMMMMMMM###***###MMMMMWWMM#*zvvvuvuuunnnnuuvvvv1<<>>>>>>>>>>>>>>>>>>>>>    //
//    MWWMMMWWMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMWMWMM*vuunxrjjjjrxnnuzj<<>>>>>>>>>>>>>>>>>>>>>    //
//    WMMWMMMMMMMMMWMMWMMMMMMMMMMMWMMMMMMMMMWMMWMMMWMMMMznnxxjt///ttjxuvc<<>>>>>>>>>>>>>>>>>>>>>    //
//    MMWMMMMMMMMMMMMMMMMMMWMWMMWMWMMMWMMMMMMMMMMMWWMWMMM*zcvnr///\/\fxvz[<>>>>>>>>>>>>>>>>>>>>>    //
//    MWMMMMMMMMMMMMMMMMWWMMWMWMMMMM#***#MMMWMWMMWMMMMMMMMM#*zvnjft\\/trc|<>>>>>>>>>>>>>>>>>>>>>    //
//    MMMMMMMMMMMMMMMMMMMMMMMWMMMMMMM*cccc#MWMMMMMMWWWMMMMMM##*zcunjt/||ru<<>>>>>>>>>>>>>>>>>>>>    //
//    MMMMMMMMMMMMMM##**#MMMMMMMv/MjfzMMMMMMMMWMMMWMMWMWMMMMMM####*zvxf((n+<<>>>>>>>>>>>>>>>>>>>    //
//    MMMMMMMMMMM##*zvnnnuz#MMMMMM|zjfjrjf/*WWMWMMMMWMWWMMMMMMMMMMMMMMM#cu[<<>>>>>>>>>>>>>>>>>>>    //
//    MMMMMMMMMMM##zcnrftfrc#MMMMMM#vzjrr\M(cMMMMWMMMWMMMMMMMMMMMMMMMWMMM#r~<<>>>>>>>>>>>>>>>>>>    //
//    WWMMMMMMMMM##*cvxt))1\jc#MMMWMMMWWWzzMxMMMWWMMMMMM###MMMWMWMMWMMMWMM#]~<<>>>>>>>>>>>>>>>>>    //
//    MWWWMMMMMMMM##*cvr/1}1)/xz##MMMMMMMMMWMMMMMMMMMM#zuuc#MMWMMMMWWMWMWMM\<<<>>>>>>>>>>>>>>>>>    //
//    MMMMWMMMMMMMM###*vnft///jxcz*######MM#MMMMMMMM#*vj|)\zMWWWMWMMMMMWMMM(~<<>>>>>>>>>>>>>>>>>    //
//    MMMMWMMMMMMMMMMM#***zz**zcxjxv*zzzzzzczz******vuf[--]\MMMMWWMMMMMMWM#-~<<>>>>>>>>>>>>>>>>>    //
//    WMWWMMMMMMMMMMMMMM#*#MMzc*n*cuz#vffftrxuvvzcvvvnf}-<+]uMMM###M#MMMMM/~<<>>>>>>>>>>>>>>>>>>    //
//    WMMMWWMMMMWMMMMMMM#M##MvxjfxxrfMMn((|\rrvvvvuuunf|?<i+[xcMzM*nvMMMMr~<<<>>>>>>>>>>>>>>>>>>    //
//    MWWMMMMWMMMMWMMMMMMM##*#MzMxxfu(MM\\/jncccvvnuunt)}<!>+|frxvMM*MM#/+<<<>>>>>>>>>>>>>>>>>>>    //
//    MWMWMMMMMWWMMMMMMMMMM#*zvuc*MMM#M#vv*####*cvnnuvr|]~!>~]cfjj\MMMn]~<<<>>>>>>>>>>>>>>>>>>>>    //
//    WMMWMWMMWMMMMMMMMMM##**zcvvnrxxuuzz###MMM#*cunxj/}-~>I!<)M#MMMn}~<<<>>>>>>>>>>>>>>>>>>>>>>    //
//    MMMWWMMWWMMMMMMMMMM##*zzvvvvcvvuxxxxcMMMM##zut}+~~~<II!<>1MM#)~~<<>>>>>>>>>>>>>>>>>>>>>>>>    //
//    MMWMWMWWMWMMMMMMMMMMzMznxxzvurf\){1\uMWMMMMMMM#****zujff?ir*]~<<><>>>>>>>>>>>>>>>>>>>>>>>>    //
//    MWMWWMMWMMMMMMMMMMMMxj\nnxzMut|){][|nMMMMMMMMMMMMMMMM###crx/~<<>>>>>>>>>>>>>>>>>>>>>>>>>>>    //
//    WMMMMWMWWWMMMMMMMMMMMM*xnj\#M\()1{{(x#MMMWWMWMMMMMWMMMMMM#*)~<<>>>>>>>>>>>>>>>>>>>>>>>>>>>    //
//    WWMWMMMWWMMWMMMMMMMM##MM##*#*f|\|)(|/rz#MMMMMMMMMMMWMMMMMM#|~<<>>>>>>>>>>>>>>>>>>>>>>>>>>>    //
//    MMMWWMMMMWMMWMMMMMM##M#zzcnrrft/f|/t/tfnvz#MMMMMMWMMMMMMMM*+~<<>>>>>>>>>>>>>>>>>>>>>>>>>>>    //
//    WWMMMWWWMMWWMMMMMMMMM##**zzzunnv**zcccunz##MMM##MMMMMMMM#*j~~<<>>>>>>>>>>>>>>>>>>>>>>>>>>>    //
//    WMMWMMMMMMMWWWMMMMMMMMM##MM#*##MMWMM#*zuvxrjrjftjxc#M#zcz*\~<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>    //
//    MMMWMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMzzcz####**zvxrj/\tx*z*#{~<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>    //
//    MMWMWMMWMWWMMMMMMMMMMMMMMMMMMMMMMMMMWWWMMWMWMMMMMM#zvnjv#j~<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>    //
//    MMMWMMMWMWMWWMWMMWMMMMWMWMMMMMMMMMMMMMWMWMWMMMMMMWMMMW#nn+~<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>    //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract HOGS1of1s is ERC721Creator {
    constructor() ERC721Creator("HOGS ONE OF ONEs", "HOGS1of1s") {}
}