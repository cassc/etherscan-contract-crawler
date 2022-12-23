// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kaede claim
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                        .,~.-?(1Jo=`           .CJ1<-~_._.                                  //
//                                .     -Jv____((1Jz`             CJ1<-~.-...                                 //
//                                ~    ,zl>~.(<<+JI`             .+1(_!- ~`_.                                 //
//                               ._- ,((1>_.`(+<1-3              .+1(-!..(~ ~.                                //
//                            ___~_ -`~<._.`..<<>>j(((+-((....   Zv<>_._.` _.i~                               //
//        `  `  `  `  `  `    .(_..(.`.~`.`..<:::!,+=(17-1vJ1/z=v1>+C `.`.._(: _  (  `  `  `  `  `  `         //
//                         .~(!``` <_ _..`..`-<>><~_~<<<<<<<<<<+J=1z<<.`.`(-.-`,!`_                    `      //
//                        `.`.~.`. ._-<..<_..._<+<_..~--!,-</~_+<<+z'.-_ .._ ._~` .`                          //
//       `                 ~_.~___~~(!.+I/_``...-~.`....`(~`  `(v~_ _ `. .._ .~ ``..                          //
//          `  `  `      ..`` .!` .-<JgK>..J+?<..``.``_.<~.` . (` ` <  _  ___   .__ `.- `  `  `  `  `         //
//                   `    <-.__ _~((dH#1+u$+><-_.    -_ _(_    `    _   _ _.1_::~:~__-_!`              `      //
//                        _<<__<<(JOWH1+dC!!` .   ..~ .~ >~   .    __.   .  (l<_ _. (.                        //
//       `        `      ~?_(-._??jqk6u6v__(+J(++<<~(+<-.<+<_-____(!.(_.-___.(z1-<_(~!                        //
//          `  `            ??0-.-?UHVz>;;<jOv<<~:_J?<?<+I<~~:::::<::+_:;<< -`(z<+`<          `  `  `         //
//                   `      .=+=jXXH6<:++??<:~~~(;+>~~_(J<!~~~<_~(<::j;;;;<_n ..1I7``                  `      //
//                        . _<dXkkHC>:::1Oz1<<<<<(2..._;>_.~~(J~(>~::+::;;<jy+..`,.        `                  //
//       `       `       .! .gWkk93::::~<~~~_~_.(X~(-(++_-(vZyyO$~~_(d<:<:<+ZS(._.>.                `         //
//          `             .dWQH9><+<:_(<~(((++==v4U6?11>Jz(I?TT7(<>?v0O1_:;<XI_<.-._          `  `            //
//                      .aV0V6+udW+?(O&Ol===lzzv__!~___(y'.`....I+?7!jyjj<;<zX<jz?--                          //
//                   `.J61dQHqqkW3<:JyzuzXfkWHR,....`.._`..``.`..`....j1<?G+<jm+Oz=-`                         //
//               `  .z==udmmHSkKC+<(kXNggH8waJ,___.`.`..`.`...(+wTTO--_1?<?3(<Hh1z!.                          //
//            [email protected]=+jVZ<+<zMM#Y>(gWmG+TH,-...`.`..`...(J+a+JgwOz1IjjZ>vHRzOx-(.                       //
//                  `.N-..z1I17TTBMNd_`.WdOJ4ks _~..`...`..`.z7<(mfX&7HNmydJHcdmHkOXXz+.                      //
//                    .Otz??<>>v;&jMNx..dkd07!........  ..`.._(y$Z>TWR_~TMBzqkdMMNHWVHmy(~                    //
//                    .dZ=?x?>dr:jVvUWHUTCz:.......`..  `..`...._7+Xk. -jgMHHHHMkzVWh?TWto.                   //
//                  .Ol==1yQsWH$:+hx>~JwwZJ(-.......`.`..`..`.`_+~-?I(JgHHy;dK4gMMNAwt&.tl                    //
//                .__(+=z?=f,HK;;;?/~~_<?~(=~.....................?1<_7c!(;j+6dVMMH""""ItXUC!`                //
//             ._.-(==zgs<<].++z;<<?___~.........`.....`..`..`........~_iI+y??dWXMHb  JrZ`                    //
//        ..(xz-(zuggH#"1;<j??>?X+.._(-.~..........--(((.-..`..`.....~..(+dC?=dWIjBW8zrv`            ~        //
//           ??TYY9"! ..z;<,ugk?+Udxvz<1--........(VCzjz?7+..........~.(CdyI==zd!?>+zI<              (        //
//    ..           _?CAgg:<[email protected]_......(KldgHgmgHdo..........(Owwy$lz_~ -Qytrro.             1_      //
//    .z.           (   ,:<-jWHMxlXx?4o-........([email protected]%..`.....(1V1dfIltOv(:dMHmyl.             (1      //
//     zI(.+<.     zz-  ..~1.4MNNzOdSx1z-........(kpWHHHHHd%.......-<(>-gWHttrA1<:[email protected]     ....Jz<`     //
//     .71zzz-`   .z_(   6;:<.HNMKztHx+Twy,.......OppppppW>........._.(XWkSOww$(:+Vs  ?TUDdN....++===?!       //
//         <z1 .   I<-~..?r;<:.MMMmZdKs>>=v<......(ppppWWt.........._<?T49GZ02(;:J<d; ~ ,>(  ?z+<1===(..      //
//    .     ?=_  ..?<<. I-v+++__HMMHAVmX+_<<<_.....?0><+C..........(JXHkudXZu!<:;P.=X..= (: .J<    ?==z=v,    //
//    z<1.  (=> J+(<(G;-.<,....._TMNHdWVWR.__...~...(c>>>.......(-UOqMHWXUU1r(;:jI`<z2~.('./~>      <====O    //
//       ..  =1,J<;1z1G>_  1......JMWHn(HWhJe+,..~...(&2....--J4D=ZdHkWWSUIV_1+j$li,~.;+^,/ ,       .Z=llI    //
//           l1<;;;j1+Cz+<. .......(VNWHHWHHkaxOO--.._~.-(JC>>>dzdHHHHHXW0f_.__._?_-:+Jb-(....   ...(llzz!    //
//    zll-_ (u>;;<J`. j21x>-.~.~....(XtZWHHHHHWHe?+C&JJv1>>>>>jXHWHkHHdX7.....-?_-:;+3(-Jv?`   .(zOwwttO>-    //
//    rwv1OwOI;+J' .~zZ(rdR?<_..~....jvOv+vwWKUMHRz?>?>>>>?jvdWWqVXdvw=........(<;+C;;;?Okl_  -wwrwXvrZ<O-    //
//    vI (Zz<+j3.--.dK(wV6dx><_~..._.`jwX(XXdMMMMMNc?>>>>+z1dmH4wQSXf_....-(<;;;+dZ?Xy$>+dSI-   ?XwXk=  -w    //
//    Xd.,X0O<>>>>>>>>>?>?16>?><_..~_ .40(UXXW#DdMMMc>>>+1+dmB!(dRX' ..-(>;;;>>>d4x<~(w+>?<l_1,-!(Xk&. .(d    //
//    Xdt (XkWkQxu&&&&+?>??z+>?<<-....._4dWKWH#RHMWSJ<;><zZd$.._W9_((J<;;;;;><+uDjI((-(S&<?J(>;;zkXWKkWXWX    //
//    WXW, (WHkYdHH3JkHWWa&&I<~.><1-_....?HHHWH8WNdd3<>+z!(C...(3;>>>>;<>>;>>+zTWAwzv77^?6&zvx;;!?HWHkHWW=    //
//    .WHH-. ?TWHN$jHHHHHHNB=<-(?>/!(+-....?5c?hdH91>>+t>._..(v<;;>>>>;>>>>;jC><<+?1??1+++ztOZ<`OX!(HHHWl     //
//      7HHHN,[email protected]_::gNx<(<(<1i-_.._ z?>?I?>>>1-..(v>>>;;;>>>>>>;+v>>>>+&+zOOOOC771;jdH) WR HHHW[    //
//    &.  "WMHHWMwMHkHpWzWWWkZWW7Hx><+?><<__- _1+<<z??>z1-J1>>>>>;<>><>?uVC11?>>>>>>>jC;;;;jdggHJH..HfgHWN    //
//    dMe da,4Wf;;>?TWfWfWfVXVC! -<?Gx>?<(J<:__.(z>I?>j?z0>>>>>>>>>_(+xIv????>????<+?;;:;jdgggggH.Vh.,WgMN    //
//    dMHHWgHHHGxz+>;>>zTWffk&..!.. _(4x>>+1z<__..?zJ<?j6>?>?>>>>><jZzC<?>>>????>1<-_(;jkdgggggggH..YL.XgN    //
//    HMWMgHh7T.J"Xk<_<>;><7UXWo.wXX&-((O>>>1z+<__..?+J6?>??>>>>>>>kC??>_!(???><<;;;j+ggggggggggggKT.J"aJg    //
//    HMMgWkCaJ74(=7+J?4&=jJ>>?THkWVWXuXZwJ>>+zz><-...?G1?>>>>>>>?J>>>><<>(1z<;;;+jWgggggggggggggggy74(=7H    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract KAEDE is ERC721Creator {
    constructor() ERC721Creator("Kaede claim", "KAEDE") {}
}