// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GORODOKOHIRAKIPPERS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#    //
//    H#H#H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH    //
//    HH#HH#H#MH"""""WMM#HMMHH#HMMMMMMMMMMMMMMMMMMMMMMHH#MMMMMMMMMMMMMMMMHH#HH#HHMMMMMMMMMMMMMMMMHH#HH#HH#HH#HH#HH#HH#HHMMMMMMMMMMMMMMMMMH#HH#HH#HHMMMMMMMMMMMMMMMMMMMMMMMMMHH#HH#HH#HHMY"""""YWMH##MHH#HH#HH#    //
//    H#H#HM"`.gHH#HN&.    ,#HHHHH]       (HQmg-,    dHH#NHR       .HHHHM#HH#HHHHNHH        QHHHMHHH#HH#HH#HH#HH#HH#HH#HMMM!       WMNa.    ?UHHH#H]    .gH]       .HaJ.   ,HHH#HH##"`  .(MHHHNJ.    H#HH#HH#H    //
//    H#H#F  JHH#HHHHHHm.  ,HH#HHH]       JHHHHHHN,  J#HHHH#       .HHHH#HH#HH#HHHHH        HHHHH#HHH#HH#HH#HH#HH#HH#HH#HHH!       HHHHb       WHH#]  .MHHHF       ,HHHM,  ,#HHH#Y`    .H#HH#H#HHx   M#HHH#HHH    //
//    HH#F   W#HH#H#HH#HM, ,H#HHHH]       JHHHH#H##L (H#H#H#       .HH#HH#HHH#H#HHHH        HHH#HH#HHH#HH#HH#HH#HH#HH#HH#H#!       HHHHN       .#HH\ .HHH#HF       ,H#H#H, .#H#M^     .MHH#HH#HH##h  WHH#HH#HH    //
//    H#H`    TMHH#HH#HH#Hp.#HH#HH]       J#H#HH#HH#L,HH#HH#       .H#HH#HH#HHHH##HH        HHH#HH#H#HH#HH#HH#HH#HH#HH#HH##!       HHH#N        #HH}.MHH#HHF       ,#HHH#N..H#M'      .#HH#HHHH#HHHh dH#HH#HH#    //
//    H#M        ?"WM#HHH#HHH#HH#H]   `   JH#HH#FJHH##HHH#H#       .HHH#HH#H#H#HHH#H        HHHH#HH#HH#HH#HH#HH#HH#HH#HHHH#!       HH#H#      `.H##:JH#HH#HF       ,HH#HHHb.#H]       dH#HH#H#HHHHHHNHHH#HH#HH    //
//    HHH;             ?TMHH#HH#HH]       JHH#HF JHHHH#HHH##   `   .#HHH#HHHH#HH#HH#        HHH#HHHHH#HH#HH#HH#HH#HH#HH#HHH!       HHH#F     ..HHH#HH#HH#HHF       ,HHH#HHHHHM`       W#HH#HH#H##H#HH#HH#HHH#H    //
//    H##N.  `            .THH#HH#]    `  ?MH"'  JHH#HH#HHH#       .HH#HH#H#HHH#HHHH        HHHH#H#HHH#HHH#HH#HH#HH#HH#H#H#!       TY"=  ..JH#HH#HH#HH#HH#HF       ,HH#HH##H##        M#HHHH#HHHH#HH#H#HH#HHHH    //
//    HHH#Mx.  `  `         /HH#HH]  `    (gg..  JHH#HH#H#H#    `  .HHH#HH#HH#HH#H#H   `    HHH#HH#H#HH#HHH#HHH#HH#HH#HHH##!  `  ` HHMH,     ?TMHH#HH#HH#HHF  `    ,HH#HHHH#H#   `  ` M#H#H#HH#HHHH#HHH#HH#H#H    //
//    H#HHH##NJ..            dHHHH]       JHHHH[ JHHH#HH#H##       .HH#HHHHH#HH#HHH#        HHHHH#HHH#HH#HHH#HHH#HHH#HH#HHH!       HHHH#b       THH#HH#HH#HF       ,HHH#HH#HHN        H#HH#HH#H#H#HH#HH#HHH#HH    //
//    H#MMHHH#HH##NaJ,  `    -#H#H]       J#HHH#cJ#HH##HHHH#   `   .HHH#H#HH#HMU#HHH        HHH#HH#HH#M"H#HH#H#HH#HHH#HH#H#!       HHH#HM        W#HH#HH#HHF       ,H#HH#HH#H#-       d#HHHH#HHH#HH#MM#HH#HH#H    //
//    HHN T#HHHHHHH#H##m,  ` (#HHH]  ` `  JHH#HHNHHHHF,#H#H#       .HH#HH#HHHM!.HH#H    `   HHHH#HH#HM^.H#HHH#HH#H#HH#HHH##!       H#HHHH        JHH#HH#HH#F   `   ,HH#HH#HHHHb    `  J#H#H#HH#HHH#M\,HH#HH#HH    //
//    H#M  /MH#HHHHHHHHHN.  .HHHH#]       J#HH#HHHH#F ,HHH##       .H#HH#HH##` -H#HH        HHHHH#H#M^ .#H#HHHH#HHH#HH#HHHH!   `   HH#HHM       `dHHH#HHH#HF       ,HH#HHH#H#HH[      .MHH#HH#HH#HM\ -#HH#HH#H    //
//    H#H.   TH##H#H#HH#M` .dHHH#H]       JHH#HHH##^  ,#HHH#  `  ` .HHH#H#MY   JHH#H        HHH#[email protected]`  .HHH#H#HH#HHH#HH#HH#!       H#HH#@   `   .HH#HH#HHHHF    `  ,HHH#HHH#HH##h.     (HHHH#HH#H#'  -HH#HH#HH    //
//    HH#_     TM#HH#H##^ .MHHHH#H]   `   JH#HMH"'    -#H###       .#HHH#"`    d#H##    `   HHHHMY'    JH#HH#HH#HH#HH#HH#H#!       H#HH#!    ..HHH#HH#H#H#HF       ,H#HH#HHHH#HH##a,`   ,W#HH#HM"    JHH#HHH#H    //
//    H#HldNmgJ...(11+.(dHHHH#HH(.....................JH#h.....................MHh.....................dHH#HHH#HH#HH#HH#h...............JggM#HHHHHH#HHHHJ..............HH#H#HHHHHH##HNa....+z1(..&gMhd#HH#HHH#    //
//    H#HHHHHH#HHHHHHHHHH#H#HH#HHHHH#HH#H#HHHHHHHHHH#HHHHHHH#H##H#HHHHHHHHH#H##HHHHHHH#HMMBYYBWMMMHHHHH#HH#HH#HH#HH#HHHHHHHH#H####HHHH#H##HH#HH#H#HH#H#HHHH#H##H#HHHHH#HHH#H#H#HHHHHHHHHHH#HHHHHH##H#HHHH#H#HH    //
//    HH##H#HHH#HH#HH#HH#HH#HH#H#H#HH#HHHH#HH#HHH#HHH#H#H#HHHHHHHH#H#H#HH#HHHHH#HH#MBzY>>+???1?+1++?M#HH#HH#HH#HHH#HH#H#MMMMHHHHHH#H#HHHHHHHH#HH#HH#HHH#HH#HHHHHH#H#HH#H#HHHH#H##HH#HH#H#HH#H#HHHHHHH#H#HH#HHH    //
//    H#HHH#H#HH#HH#HH#HHH#HH#HHH#HH#HH#HH#H#H#H#H#HHH#HH#H#H#HH#HH#HH#H#HMMMMBY7>11+???=1zrwwwwvzwwoJM#HH#H#MH#MMMYW8wvzwzzzzTMHHH#HH#H#H#HH#HHHH#HH#HH#HH#HH#HHH#HH#HHH#H#HHHHH#HH#HH#HH#HH#H##HH#HH#HHHH#H#    //
//    H##HH#HH#HH#HH#HH#H#HH#HH#HHH#HH#HH#HHHHH#HHH#HHHH#HHH#HH#HH#HHH#M61??=++<>?>>?+zzzwXXXXXHfVXWWWkMH#MHB1OtOwwvXwwZXWWkwwXdMHHHH#HHH#HH#HH#H#HH#HH#HH#HH#H#HHHH#HH#HH#HH#HH#HH#HH#HH#HH#HHHH#HH#HH#H#HH#H    //
//    HH##HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#H#HHH#HH#H#H#HH#HHH#HH#HH#HB<>>?1===1+1zwXXXXXWWyyWHHWWkWpfWHozC+wrvXXXwdHHHqHWHkWyWHkXMHH#HH#HH#HH#HHH#HH#HH#HH#HHHH#H#HH#HH#HHH#H#HH#HH#HH#HHH#HH#HHH#HH#HH#HH#HH    //
//    H#HHH#HH#HH#HH#HHHHH#HH#HH#HH#HH#HH#HH#H#HH#HH#HHH#HH#HH#HHH#[email protected]+>[email protected]@HMHWHkI7HM#HH#HHH#HH#HH#HH#HH#HH#H#HH#HH#HH#HH#HHHH#HH#HH#HH#HHH#HH#H#HH#HHHHH#HHH    //
//    H#H#H#HHH#HHH#HH##HHH#HHH#HH#HH#HH#HH#HHH#HH#HHH#HH#HH#HH#HH#HM><[email protected]@[email protected]@[email protected]@HROzwVMHHH#HHH#HH#HH#HH#HH#HH#HH#HH#HH#HH#H#H#HH#HH#HH#HH#HH#HH#HH#HH#H#HHH#H#    //
//    HH#HH#H#HH#HHH#HHH#HHH#HHH#HHH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHHB>([email protected]@[email protected]#H#HH#HH#HHH#HH#HH#HHH#HH#HH#HH#HHH#HH#HH#HH#HH#HH#HH#HHHH#HH#H#HHH#H    //
//    H#H#HH#HH#H#HHH#HHH#HH#H#HH#HHH#HHH#HH#HH#HHH#HHH#HH#HH#HH#HMC1zwVwX0XWZOzI<Ofu0wwXZXXWHHHkHMH#[email protected]@@[email protected]#HH#HH#HHH#HH#HH#HHH#HHH#HH#HH#HHH#HH#HH#HH#HH#HH#HH#HHH#HHHH#HHHH    //
//    H#H#H#HH#HHH#HH#H#HH#HH#HH#H#HHH#HHH#HH#HH#HHH#HH#HH#HH#HHMB<+zzOOwXyXXkwvC<[email protected]@[email protected]##HNWM#HH#HH#HHH#HH#HH#HHH#HHH#HHH#HH#HH#HHH#HH#HH#HH#HH#H#HHH#H#HH#H#H    //
//    HH#HH#HHH#HH#HHH#HH#HHHHH#HHH#HH#H#HH#HH#HH#HH#HHH#HH#HH#[email protected]<z==1rOwXwOX0O<[email protected]@HHHHMHXWQHHMMWHWMHHHWM#HHHHNHWM##HH#HHH#HH#HH#HH#H#HH#HHH#HH#HH#HHH#HHH#HH#HH#HHH#HHH#HH#HHH#    //
//    H#H#HH#HH#HHH#HHHH#HH#H#HH#HH#HHH#HH#HH#HH#HH#HH#HH#HH#HHM31zv<<?zd0trwXv<++Ozzt=zv<[email protected]@@HHMHXMMHHMHHHHHMNMNHM#HH##HMMMkHMH#HHH#HH#HH#HH#HH#H#HH#HH#HH#H#HH#HHH#HHH#HH#HH#HHHH#HH#HH    //
//    H#HH#HH#HH#HH#H#H#HH#HH#HH#HHH#HHHH#HH#HH#HH#HH#HH#HH#[email protected]>(+zzZzzwwr><1I1lz1+zv<<[email protected]@@[email protected]#HHHHHHHHHmZHM#HH#HH#HH#HHH#HHH#HH#HH#HH#HH#H#HHH#HHH#HH#HH#H#HH#HH#H    //
//    HH#HH#HH#HH#HH#HHH#HHH#HH#HH#HH#H#HH#HHH#HH#HH#HH#HH#HHME-+OO><zZOOzZOOz<(11+l1z=zI;+1wOXUVI=<[email protected]@@[email protected]#HHHHHNWkXWWMHHH#HH#HH#HHH#HHH#HH#HH#HHH#HHH#HH#H#HH#HH#HH#HH#HH#HH    //
//    H#H#H#HH#HHH#HHH#HH#HH#HHH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HKOZ1v<+zzzz+OwVz<<<[email protected]@@H#@@@mWHHMNNNNNNNN##MMH##HHMHNXWM#HHH#HH#HH#HH#H#HH#HH#HH#HHH#HH#HHH#HH#HH#HHHHH#HH#HH#    //
//    H#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HHHH#HH#HH#HH#HH#HHH#HH#HM6w0<1<z=<1zzzrv++<<zlt<;>[email protected]@@@H#MMHHWkMM####M#####HMMHH#HHHHHkW#H#HH#HH#HH#HH#HH#HH#HHH#H#HH#HH#HHHH#HH#HH##HHH#HHH#H    //
//    HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#H#HH#HH#HH#HH#HH#HHH#HH#@=z1z+<+?zlOOlz+zz:~<z11?>[email protected]@@[email protected]##MNNNNNMNNMMH#HHHMNMHHH#HH#HH#HH#HHH#HH#HH#HH#HH#HH#H#H#HH#HHH#HH#HHH#HHHH    //
//    H#H#H#HH#HH#HHH#HH#HH#HH#HH#HHH#HH#HH#HH#HH#HH#H#HHH#HHkOtzz+zz<<?zI1==1I<:(<<<[email protected]@@@[email protected]#HH#HH#HH#HH#HHH#HHH#HHHHH#HH#HHH#HH#HH#HHHH#H#HH#H#H    //
//    H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHHH#HH#HH#HH#HH#HHH#HHH#HWHv1zOzzO+zzv<<?>><~+<++([email protected]@@@@@HHHHHXWgM#MNNNN#[email protected]#HH#HH#HH#HHH#HH#H#H#HH#HH#HHHH#HH#H#H#HH#HH#HHH#    //
//    HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#H#HH#HHH#HH#HH#HH#HH#HHH#MKW0?OwZz<<<;;+<;_(>1z<[email protected]@@@[email protected]@HWWWMMN##NNNMMMMMMMMMNMHMgmHHMHH#HH#HH#HH#H#HH#HHH#HH#HHH#HH#H#HH#HHHH#HHHHH#HH#HH    //
//    H#H#H#HH#HH#HH#HHH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#H#HHH#MSI<?><<<<~~<<;<(<+l<_<[email protected]@@[email protected]@[email protected]#MMMN#NNMMMMMNMMNMHMH#HHH#HH#HH#HH#HHH#HH#HHHH#HH#HH#HH#HH#HH#HHH#H#HHH#HH#H    //
//    H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HH#HHH#HHH##MHkI<(<~<<~~_(~<<(zv=v<<~([email protected]@@[email protected]####H#NNNMMMMMMMHHHHH#HH#HH#HH#HH#HH#HH#H#HH#HH#HH#HHH#HH#H#HHH#H#HH#HHHH    //
//    HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HH#HHH#HHM8ZC1<<<<~__~:(~(+++zz+>~_<[email protected]@HHHH#MMNN#NWHHMHMHM###NMMMMMMNNMM#HH#HHH#HHH#HH#HH#HH#HH#HH#HH#HHH#HHH#HHHH#HHHHH#HH#H#H    //
//    H#H#H#HH#HH#HH#HH#HHH#HH#HH#HH#HHH#HH#HH#HH#HH#HH#HHNzOzv<~?Iuz1=<+zzlzI<<<<_(~<[email protected]@HHHHHHNN###MHWWMMgHHMM##NMMMMNMMMMMHHH#HHH#HHH#HHH#HH#HH#HH#HH#HH#HH#HHH#H#HH#H#HH#HHH#HH    //
//    H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HH#HH#HNVOOlz<><<?=?<<<1rI<~<(;:_([email protected]##########[email protected]@[email protected]#HMHH#HH#HH#H#HH#HHH#HHH#HH#HH#HH#HH#H#HHH#HH#HH#HHH#HHH#H    //
//    HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HH#HH#HHQgNm<zo+(__(_(1z<___(<<<zVOCz1+7TzzOVVOXHUUUUWUUUWWHHHMMMMMMMMMMMM##[email protected]@HH###MMM#NMMHHHMHH#HH#HHH#HH#HHH#HHH#HHH#HH#HH#HHH#HHHH#HH#HH#HH#HHH#    //
//    H#H#H#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HHH#HH#HH#HH#HH#HH#HHHH#NOr>:(((l=<<<~~_``  ``````` ``` ` ` `` ` ` ` `  ` `` ` `` ` `.###[email protected]@MMHHNMNHHMMMkHMHH#HH#HH#HH#HH#HH#H#HH#HHH#HHH#HH#HH#H#HH#HH#HH#HH#HHH    //
//    H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HH#HH#HHHHHNItzOO1==<:~~~_` ``  `   ` `  ` `  ` ` `  `` `` ` ` ` ` ` ` .H#[email protected]@[email protected]@MMMHNMMMHHQMHHH#HH#HHH#HH#HH#HH#HHH#HH#HHH#HHH#HH#HH#HH#HH#HH#HH#H#HH    //
//    HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HH#HH#H#HHHNvvOzz=1<:_~~_`  `.((((-.....  ``  ` ` `  ``.JJJJ..-...` ` .HHHH#[email protected]#MMMHHH#H#HH#HH#HH#HHH#HH#HH#HH#HH#H#HH#HH#HHH#HHH#HH#HH#HH#HHH#H    //
//    H#H#H#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HHH#HH#HH#HH#HH#HH#H#HHHHRwVOzz<::~:_ `  .uuuuX==?=z ` `` ` ` `` ``JfVVfS????<` ``.HHHHHH###MHHMMMHHHHHHHH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HHH#HH#HH#HH#    //
//    H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HH#HHHH##HHNmzOOzz::(:<` ``.zuzuw=?=?z `  `` ` ` `` `(fVVfS?>??<`  `.#HHHHHHHM#MHMM#HHH#H#HHHH#HH#HH#HH#HH#HH#HH#HH#HHHHH#HH#HH#HH#HH#HH#HHH#HHH#HHHH    //
//    HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HH#H#HHH#HHM3(1O>     ` `  =1==v`````  ` `(_+zd{  ``(1111>____``` ` _````````_WHM#H#H#HH#H#H#HH#HH#HH#HH#HH#HH#HH#HH#H#HH#HHH#HH#HH#HH#H#HHH#HHH#H#H    //
//    H#H#H#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HHH#HH#HH#HH#HH#HH#HHHHH8zzZ>`  `  ` ` ????> `````` ``(<zwW}` ``(?>>?<...``` `  ` ` `     dMHHHH#HH#HHH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HHH#HHH#HH#HHH#HH#H#HH#HH    //
//    H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HHH#HH#H#HNZ<<_     ` `  ++<<> `````  ``(<zwW} ` `(<<<<<``..`` `` ..........dMHH#HHH#HH#HHH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HHH#HH#HH#HHH#HH#HH#    //
//    HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HHH#HH#HH#N,(=<::~_ ` ` ``` ` ` `  ``  __1wX{ ` ` ``` ``   ` `  .MMHHHHMMHkHH#HH#HHH#HH#HHH#HHH#HH#HH#HH#HH#HH#HH#HH#HH#H#HH#H#HH#HH#HH#HHHH#HH#H    //
//    H#H#H#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HHH#HH#HH#HH#HH#HHHHHHMmJzz<:~~` ` `  ` `` ` ` ` ``(:1wX{` ` `  ` ` ``` ` ``[email protected]@HfMHHHH#HH#HH#H#HH#HHH#HHH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HH#H#H#HH#HHH    //
//    H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HH#H##HHHHNz?;;__....................(+zwWa(((((((((((---....-(@[email protected]@[email protected]@HKWH#HH#HHH#HH#HH#H#HHH#HHH#HHH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HHH#HH#HH#H    //
//    HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HH#HH#H#HHR<>><<_((>>1Olv=??<<<++<:<<+zwXHM#H#H##NNN#[email protected]@[email protected]@[email protected]@[email protected]#HH#HH#HHHH#HHH#HH#H#HH#HHH#HHH#HH#HH#HH#HH#HH#HH#HHH#HH#HHH#HH#HH    //
//    H#H#H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HHH#HH#HH#HH#HHHHH#[email protected]:<?>?+>>>>=zI<>>>+1w0z<<:_(zwXHHH##NNNNN##[email protected]@@@@@[email protected]@@@[email protected]@HqHWHHH#HH#HH#H#HH#HH#HHH#HH#H#HHH#HHH#HHH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#H    //
//    H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#H#HHH#H#@~;>+???>>>><;;>++zXKI<<;;~(zwWHM#####NNN##[email protected]@@@[email protected]@@@@@[email protected]#HH#HH#HH#HH#HHH#HHHH#HHH#HH#H#HH#HHH#HHH#HH#HH#HH#HH#HH#HH#HH#HH#    //
//    HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#H#HHH#Hn(<;>?==?>>;<<>+zwXHS<(+(<_(wXWHHH#HHHHNNN#[email protected]@@[email protected]@@@[email protected]#HH#HH#HH#HH#HH#HH#H#HH#HH#HHH#HH#H#HHH#HHH#HHH#HH#HH#HH#HH#HH#HHHH    //
//    H#H#H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HHH#HH#HH#HHHH#HHH#N<:<>>>><<;;+1zwXWm9OzwQmszzwWHHMMMMMMMNMNN#[email protected]@@@@@@@@@[email protected]@@HMHHH#HHH#HH#HH#HH#HH#HH#HH#HHH#HHHH#HHH#HH#H#HH#HHH#HHH#HH#HH#HH#HH#HH    //
//    H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#H#HHHMI(<>>>>>;+1ztwXWWSI?zvUWHkXWHHMMNNNNNNNNNN##[email protected]@@@@@@@[email protected]@@@gMHH#HH#HH#HHH#HH#HH#HH#HH#HH#HH#H#HH#HH#HHH#HH#H#HHH#HHH#HHH#HH#HH#H#H    //
//    HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HHHH#HH#N!(???>>>?=lOwyWSz?=zwXXffWWHMMMMM#NNNNNNNN##[email protected]@@@@[email protected]@@[email protected]#HH#HHH#HHH#HHH#HH#HH#HH#HH#HH#HH#HHH#HHHH#HHH#HH#H#HH#HHH#HHH#HHH#    //
//    H#H#H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HHH#HH#HH#H#HH#HHN<<><[email protected]@[email protected]@[email protected]@@HMHHHH#HH#HH#H#HH#HHH#HHH#HH#HH#HH#HH#HH#HH#H#HH#HH#HHH#HH#H#HHH#HH#HH#H    //
//    H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HH##~(;;1O===zOrvOtvwtzX0XWHHkHMHHHWWHHHM#[email protected]@gMHH#HH#HH#HHH#HH#H#HHH#HHH#HHH#HH#HH#HH#HH#HH#HH#HHH#HHHH#HHH#HH#HHH#HHH    //
//    HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HHH#HH#HN_~<<+1llzOOOIz1wXWkXwWHmHHMHkHHHHHHHHHMH#HMNN#[email protected]@@HHHHH#HH#HH#HHHH#HHH#HH#H#HH#HHH#HHH#HH#HH#HH#HH#HH#HH#H#HH#HH#HHH#HH#HH#    //
//    H#H#H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HHH#HH#HHH#HHHM,_(+<1tzzO???1wXWWkXWHHqqHHWMMMMMMMMHMMM#[email protected]#HH#HH#HH#H#H#HH#HH#HH#HH#H#HHH#HHH#HHH#HH#HH#HH#HH#HH#HH#HHH#HH#HHH#HH    //
//    H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HHH#[email protected]#NNNNNNN#M#MMHH#HHH#HMMgMHHH#HH#HH#HH#HHH#HH#HH#HHH#HHH#HH#H#HH#HHH#HHH#HH#HH#HH#HH#HH#HH#HH#HH#HH    //
//    HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#H#HHe-<jO=ltOOOzwWmHWVrrvzuuXWWWgM####NN##NN##[email protected]#HH#HH#HH#HHH#HH#HH#HH#HHH#HH#HHH#HH#H#HHH#HHH#HHH#HH#HH#HH#HH#HH#HH#HH#    //
//    H#H#H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HHH#HH#HHHH#H#@[email protected]@HHMHHHHHH##NN###[email protected]@HgHHHHWMHHH#HH#HH#HH#HH#HH#HHH#HH#HH#HHH#HHHH#HHH#HH#H#HH#HHH#HHH#HH#HH#HH#HH#HH#H    //
//    H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#H#HHHM8z1<[email protected]#N#HMHMMgggmHHMH#HH#HHH#HH#HH#HH#HH#HHH#HH#HH#HH#H#H#HH#HH#HH#HH#H#HHH#HHH#HHH#HH#HH#HH#HH    //
//    HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HM"^_;__(<[email protected]#[email protected]#HH#HHH#HH#HH#HH#HH#HHH#HH#HH#HH#HHH#HH#HH#HHH#HHH#HH#H#HH#HHH#HHH#HH#HHH    //
//    H#H#H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HHH#HH##b`__._~~(+OwOzzlOzzz<[email protected]#HH#HH#HHH#HH#HH#HH#HH#HHH#HH#HH#HHH#HH#HH#HH#HHH#HH#HHH#HH#H#HHH#HHH#HH#H#    //
//    H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HHHR. . .._:;+z<=zrO<>>>+zrvwzrXXwyHmqHHMMHHMHHHWpppppVWWMHH#HH#HH#HHH#HH#HH#HH#HH#HHH#HH#HH#HH#HH#HHH#HH#HH#HHH#HHHH#HHH#HH#H#HH#HHHH    //
//    HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HHHMR.P`.~(;><<+llI<<<<zzvOwXXXXXdWpHHmHHWUUWXUXWbppWVWHH#HH#HH#HH#HHH#HH#HH#HH#HH#HHH#HH#HH#HH#HH#HHH#HH#HH#HH#H#H#HH#HH#HH#HH#HH#HH    //
//    H#H#H#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HH#HHH#HH#HH#HH#HH#HHHHHM'  ~~::<<=z1v?>:>==zwwXXWVXwwXbHHUXvIzwvtwffVyyXXHH#H                                                                              //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GDH is ERC1155Creator {
    constructor() ERC1155Creator("GORODOKOHIRAKIPPERS", "GDH") {}
}