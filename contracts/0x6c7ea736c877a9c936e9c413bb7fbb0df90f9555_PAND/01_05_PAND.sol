// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Paranoid Androids
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//                                       n.nr4?+nMhnxh..                                      //
//                                    ..J?%!!!!!!`(<!!(*L..                                   //
//                                  'd?!!!!!!!!!!!:!!!!!!(M                                   //
//                                 x?!!!!!!!!!!!!!<!!!!!!!!?M                                 //
//                                r!!!!!!!UU)UUX!!!!~:?!!!!!!*M                               //
//                              n=!<!!Xd$$#o$$#?!!!!!!!!!!!!!!!n.                             //
//                            xx)!!!!4$$FRP?!!!!!!!!!!!!!!!!!!~<*..                           //
//                            M<!<!!!MMM.!!!!!!!!!!!!!!!!!!!X!!<:4                            //
//                            M!)!!!!?(!!!!!!!:!!!!!!!!!!!!!#$X!:~M                           //
//                            M!!!!!!!!!!!!<><!?!!!!!!!!!!!!!Ri&!<C                           //
//                            M!!!!!!!!!~` <!!!!!:!!!!!!~!!!!!$$b!M                           //
//                            M!\!!!!!!<<:/~::!~<!<'!!!!<!!!!!M?$H4  ....   .....             //
//                            MX!!!!!.~ ~.xHR!:!!!!!!'!!~!!!!!.M?4M  fh/M   [email protected]             //
//                            MM!!!!<!!!WM#>:/!<t!!\!!!!`!>!!!X!!<M  >MMh   4tMP              //
//                             f!!!!!!!\$  %u'?J%!H!!!!!'! !!!:>!!/  MMMM  MXHMXMd2N>         //
//                            nH!!!!!:!!7Wi$$$$NWP!~!<)R!<!!!!!!\!   !?!M 'k!#XMMdM?>         //
//                            4X!!!!<!~!h$$$$$$$$R!X>-+)~!!!!!!!HX<  /MM?..XM<MMTMM4r         //
//                            4M!!<<<!<~/X$$$$$$RU(( 3!~!'!~\X!!M?d  MMM/MMMMMMdM*M>.         //
//                             'h!<<<~<(<M5$$$$$$B$$$R!` !<?XX~HH)M  MkMM4%M(M(MLM>M?C        //
//                              PXX<~<`d)Q$$$$$$##9$R!:<<\FfMXM!MMH*<M?MMkMM<XMMMMM3Mh        //
//                               "M?<<[email protected]$$$$MT~<<:JMM """)d.<<MMWMMMMMM:!MMhHMX)        //
//                                Mc<<<[email protected]#!` < <n<M*=     ^kh<<=dMi!MMMHx!<</*"         //
//                                !$$$iL'>!#"`<L"!`n!d<d3        M8x<iMRMH<MM*MkxMh           //
//                              nh$~$$$$  nnH$MhMMM%CU3C*M<      4X$MM99R!MXMM:/              //
//                             4Mb$e.$$$ HM"`$ """9$$$$$$$CMJ      M$RRM!<<MMMMJ              //
//                          nnM!.P$$$$$?#RMMX3. <<<<"$5"  ^$K=     M#$?!<<:?M*<Mr             //
//                    . ....M"<L$$$$Ib$$$#[email protected]$$ << $9. < #$MM    3MP$HHMMH~<XM              //
//                    MSb$$"<\$$$$$$X$$W$$$$$$$$F<<< [email protected]@$Et    JP8^*MMMMMMHC              //
//                  M"*$$$ <<@$$$$$$MP$$$$$$$$$$     R$$$NW$$R\    >[email protected]>               //
//                MM  <$$ <<~$$$$$***"$$$$$$$$$"       $$$$$$!M    .$$$$I$R8x*(               //
//                MH' z5$    [email protected]:$$$$$$$$         $$$$$$4M    M#$$$$$$$$R>               //
//                MXM9X$$    $$$$eo$e$$$I$N$$$i        $$$$$$4M    .dWF7$*$$R4>               //
//                MH$N$$$  .$$$$$$$$$$$$$$$$$$$c      3$$$$$RXM    d$$$MMMMMP*>               //
//                "M$$$$$ $NdN$$$$3$$$$$$$$$$$$B      '$$$$$N94    "$$$$NM%>"                 //
//                  ?$$$l$$$$$$$$$$$$$$$$$$$$$$R    X   "$$$"%M  *M #$$$RMM                   //
//                  M$$l$$$$$$$$$$$$$$$RMMMR$$$M    M     $$KxM  M   $$$MxM                   //
//                  M$%$$$$$$$d$$$$$$$$MMMMMMMM!   <.      #$hX  M   $$$MM*                   //
//                  M$$$$$$$$*"*$$$$$RMMMMMMMMP    hX       "$M  ~  J$$Mx*                    //
//                  "J/R$$$Rf<  ^$$$MMMMMMMM9`   iMM\r       "/M"   $$$MM                     //
//                   M$?MMMM>    [email protected] XMMMX)M        #f    $$R%L                     //
//                   M$  ""3k    $$$$$*[email protected]$$M)  4x             $$MMM                     //
//                   *$   %$$   x$$#...` ..  'MMMMH  -*.           $$$PP>                     //
//                    R  :'$$L' $$$!    `'   .M!h"n    M           $$MH"                      //
//                    f ~  '$$ d$$$       .!` M        '/          $MMh                       //
//                    M  '  $$L$$$$e...nnMMMMf"        MHN        <RM^P                       //
//                    4     '$K$$$$$$$MMMMM*M>         '"/$       :M!MM                       //
//                    dL     $$$$$$$$$$8MMMLM>           M$       H*M=                        //
//                    xM     4$#$$$$$$$$M8$$(>           M7L    xM)*'                         //
//                           '$%$$$$$$$$$$$$$M           *4$  u$MhM                           //
//                      L    J$$$$$$$$$$$$$$$$t.           hN$$PH                             //
//                      M    $$$$$$$$$$$$$$$$$$>n          MHRC""                             //
//                      M    $$$$$$$$$$$$$$$$$$$M..        " ""                               //
//                      %    [email protected]$$2>                                           //
//                     P     [email protected]$HnC                                         //
//                    M~     $$$9$$$$$$$$$E$$$$$$$NP4                                         //
//                  nn)      '$$%$$$$$$$$$R$$$$$$$$$HM.                                       //
//                  MM$       #$NR$$$$$$$$X$$$$$$$$$$M? .                                     //
//                  M)$       x$$K$$$$$$$$?$$$$$$$$$$$MhM                                     //
//                  M$$       Mb$$4$$$$$$$33$$$$$$$$$$NMLhx                                   //
//                  M$$      :P>N$$G$$$$$$$N$$$$$$$$$$$$M M                                   //
//                  M$$      M "!R$$*$$$$$$$$$$$$$$$$$$$~ /:                                  //
//                  f$F     xr  /HRRNB$$$$$$f$$$$$$$$$$$  M4M                                 //
//                  d$"    .)\ 4!(?R*$$$$$$&$$$$$$$$$$$  dMHM                                 //
//                dP$$     M  nMt)[email protected]$$$$$2$$$$$$$$$  z$MMf                                 //
//                Md$$    :M  M)4MMMXR$B$$$$M9$$$$$$$> .$$RMMMM                               //
//                M$$~    MC  M%MMMMX97NR$$$M9$$$$$$P  $$$$MM?M                               //
//              ..3$$$.  .h-  MX9MMMMM?X$$$$M8$$$$$$  $$$$$MM~M                               //
//              JM$$$RMh M    PCXMMMMMMXxRRMM$$$$$$F x$$$$$MM 4                               //
//            M3NW$$$MMMJM    JhhMRMMMMH9?!*M9$$$$$  $$$$$$M" H                               //
//           C3$$$$$*$$RMM   .RMMMMMMMHMMP)H!9$$$$$e$$$$$$$` JMMM                             //
//          'M$$<<~?*$$etM  nd4MMMMMMMMXHHH!X8$$$$$$$$$$$$   MMM"                             //
//          '*M)Ri><<$$$\*  MktXMMMMMMMMM!MH9$$$$$$$$$$$$" .MMMM.                             //
//            4?bMHRm$$$M'  M3MMMMMMMMMHM9XMM$$$$$$$$$$$F :MMMMtM                             //
//          Mn9$$$$MMM**    MWMXMMMMMMMMMMXhP$$$$$$$$$$$  RMMMM4M                             //
//        [email protected]$$$$$M?M""    MRHMMMMMMMMMMMXSM$$$$$$$$$$  @MMMMM4M                             //
//      .n*$$$$$$$$E#4      MRMMMMMMMMMMMMS*H$$$$$$$$$` d$MMMMM4M                             //
//    . MQ$$$$$$$$%XM/      MRMMMMMMMMMMMMhXk$$$$$$$$F  $$MMMMM4M                             //
//    [email protected]$$$#$$$$3H"        MMMMMMMMMMMMMMPEM$$$$$$$$$e$$MMMMMM4M                             //
//    M$$$#>!d$$PM          [email protected]$$$$$$$$$$$$MMMMMMXM                             //
//                                                                                            //
//      _______ _                     _   _____ _ _           _             _                 //
//     |__   __| |              /\   (_) |_   _| | |         | |           | |                //
//        | |  | |__   ___     /  \   _    | | | | |_   _ ___| |_ _ __ __ _| |_ ___  _ __     //
//        | |  | '_ \ / _ \   / /\ \ | |   | | | | | | | / __| __| '__/ _` | __/ _ \| '__|    //
//        | |  | | | |  __/  / ____ \| |  _| |_| | | |_| \__ \ |_| | | (_| | || (_) | |       //
//        |_|  |_| |_|\___| /_/    \_\_| |_____|_|_|\__,_|___/\__|_|  \__,_|\__\___/|_|       //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract PAND is ERC721Creator {
    constructor() ERC721Creator("Paranoid Androids", "PAND") {}
}