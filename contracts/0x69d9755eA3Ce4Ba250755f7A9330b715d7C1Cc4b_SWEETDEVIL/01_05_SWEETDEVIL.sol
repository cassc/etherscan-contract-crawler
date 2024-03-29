// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SWEET DEVIL
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                               //
//                                                                                                                                                                                                               //
//                                                                                                                                                                                                               //
//                                                                                                                                                                                                               //
//                                                                                                                                                                                                               //
//        `   `   `   `   `   `   `   `   `   `   `   `   `   `   `   `   `   `   `   `  `   ``  ` .. ```` ``  `  `   `   `   `   `   `   `   `   `   `   `   `   `   `   `   `   `   `   `   `   `   `   `      //
//                                                                                        `..JXbkHHHbHHVWbHHHgJdmx, `                                                                                            //
//                                                                                 `   .(XfVyUXWWHWpWyXZWpkkkHmmmHmHHgHa.                                                                                        //
//       `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `   `[email protected], ` `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `       //
//                                                                                .XWW0wXkwkXwXXXXXWWkWWppWppfWbbqqqmHgmqqqqmHm,                                                                                 //
//                                                                              [email protected]                                                                          `    //
//                                                                           `[email protected]@@[email protected]@@@[email protected]@@@[email protected]@Ma                                                                              //
//       `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  ` ([email protected]@[email protected]@@@@@[email protected]@[email protected]@@@@@[email protected]@@[email protected]@[email protected]@HHN.  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `       //
//                                                                          ([email protected]@[email protected]@[email protected]@@[email protected]@@@[email protected]@@@@@@@@@@@@[email protected]@@[email protected]                                                                           //
//                                                                         [email protected]@@@@@@@@@@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]|                                                                          //
//                                                                        [email protected]@@@@@@@[email protected]@[email protected]@@[email protected]@@@@o                                                                         //
//       `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  ` [email protected]@@@[email protected]@[email protected]#[email protected]@@[email protected]@[email protected]@@HN. `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `    //
//                                                                       [email protected]@@[email protected]@@@@HHHHHH####N##[email protected]@@@@@[email protected]                                                                        //
//                                                                    ` `[email protected]@HHHW0I1???zwwXpbkqqqHHMMMMMMHH#H#H###[email protected]@@MMHHHHHMH;                                                             `  `      //
//      ` `  ` `  ` `  ` `  ` `  ` `  ` `  ` `  ` `  ` `  ` `  ` `  `   [email protected][email protected]@HHHHHH#H#[email protected]@@@@[email protected],`  ` `  ` `  ` `  ` `  ` `  ` `  ` `  ` `  ` `  ` `  ` `  `           //
//                                                                       ([email protected]@@@HHHH###HHHM#[email protected]@@@gmqkHHMMHHHHM,                                                               `     //
//         `    `    `    `    `    `    `    `    `    `    `    `    ` ,[email protected]@HHHHMMMHM9<[email protected]@M!     `    `    `    `    `    `    `    `    `    `    `   `  `      //
//                                                                        [email protected]@@HHMMBYC<__`[email protected]%                                                                      //
//      `   `  `  `   `  `  `   `  `  `   `  `  `   `  `  `   `  `  `    .HHgmqHHmqqkHfyZwO=1zZOwwWqqHHHYYT><:~~~_`.``..dHmHqkkpHHWVpHHmHH)  `  `  `   `  `  `   `  `  `   `  `  `   `  `  `   `  `   `          //
//                                                                     ` [email protected]@HHHqgHHbbpWuzzwwvwwXyWHH9=<:~~____`.`.``.`[email protected]                                                                 `     //
//       `         `         `         `         `         `            [email protected]@MMgHMqqkkWyZXXWWXVWWWB=<:~~_~__..```.``.`.``[email protected]         `         `         `         `         `       `   `        //
//         `  `  `   `  `  `   `  `  `   `  `  `   `  `  `   `  `  `  ` ,[email protected]@@@HggqWWWWpfVWW9V>~____.`..`.``.``..`.`.`[email protected]  `  `  `   `  `  `   `  `  `   `  `  `   `  `  `   `  `               //
//                                                                      ,[email protected]@@[email protected]@gmHkbpW96>~__..``.```.``..`.`.``.``.`._SHWXZXWWVWbkqqHN                                                           `   ` `     //
//                                                                     `,[email protected]@ggqkHm9=<~__.`.``.`..``.`.``.``.`.`.``. ([email protected]`                                                                      //
//                                                                      [email protected]@@@gqqHBo-__.`.``.`.``.`..`.``.`..`.`.`..``[email protected]@P                                                                       //
//                                                                      .##[email protected]@gHYY77T4Wk&...`.`.``.``.`..`.``..(([email protected]=                                                                       //
//                                                                     ` MN##[email protected]+zz&u&&+vYWA&.`..`.``.``.-(dXWKY=!-...`[email protected]@[email protected]`                                                                       //
//                                                                       HNNN##[email protected]<?XHNNNNNNgkm+?^.``.`..`.,jUY9Ggg&JJ+-___-..0YY_.dMMH#`                                                                        //
//                                                                       .NN##HH8<::_jTYYT"WMMMNk-.`.`.``..([email protected]&x_.` __<<(HHM%                                                                         //
//                                                                        WN#[email protected]::~::(1<_(WkXXY?O>.....`.-([email protected]"MMH#7UU4>..``(+_<<j#HMM;                                                                        //
//                                                                        ,M#MBd<:~__~:<<(___.__(<_.....-_<z<_.4kkWY!.(+C~_`..(c_(+HMkWF`                                                                        //
//                                                                        `dMNIdI:~...~_~~~~~..~_~......~:<~__(_((-(<<>~__`.`.($_JHB=.Z`                                                                         //
//                                                                         .WH<?6:~~................~..~~:~~~~~~~~~~__.`..``.(<_(    `                                                                           //
//                                                                           (Z1O<~~~~::~__~~....~~.~~~~_::~................_7~_`                                                                                //
//                                                                           <..(o~~~~::::~~~~~~_~_ ` ~~_::~.~.~~~~~~~~...-((<<1-                                                                                //
//                                                                         ` 1--+Tc~~~~~~~~~~.._:__  ...__<...~~~~~~~~~~..(7>__:>                                                                                //
//                                                                      ` .~.-(<?i(x~~~~~~....._((jo-(J+_~__...~~~~~~~~..(: -Vz?3.                                                                               //
//                                                                       _..(: jO:<(<.......``..`__<+<<~__.`....~~~~~...(! (_-J!~<<.                                                                             //
//                                                                     `._.`-i-dC~<:.<_.`..-(-..-_____--.... `........__! .<.(I- <:<                                                                             //
//                                                                       <..`....(+} .i_.``.._?4x-.  ``_(1zY7~```.`` (!    :_._<!_:+_                                                                            //
//                                                                       .<-...-(+7    1,.```._~_<1i(.-~<:~`.`..`. (?      (<-..._<<`                                                                            //
//                                                                         _?!~?`       (o-..``._~(_--_~~_.``.`..(>          ?i-(<?`                                                                             //
//                                                                                       (V&-..`.`. __```.`.. .J>+:                                                                                              //
//                                                                                       .I<?3-..````.``.`..Jz<:;j+(-<_-..                                                                                       //
//                                                                                   ..?71I::::<<_-....(-+<<::;;;JkdO+<<<<j_                                                                                     //
//                                                                               ` .Z>:++db:::::~~~~~:::::~::::::?SW6??zOxz}                                                                                     //
//                                                                               J<<+1zOwd$::::~_........._____~~_JI><(?OvUk`                                                                                    //
//                                                                               2:;1OXXzU>~~~~~.....```.`......-J<<+<_-(Oyw.                                                                                    //
//                                                                               W<:<<?OU$-_:~~_...`..`.`.. ..(+<::<jza?!(dw0Oz(..                                                                               //
//                                                                           `  .vI~~~~~~_~<<?77<<<+zlz+&sOz><::::~(zOz<_(dZIz<<<+zC1(....  ``  `                                                                //
//                                                                      ` ` ..<<1I<~~~........~.~~~~~~~~:<<?<<<:~:::7C1zzuUIz<::::::::::;<?<+71Q,                                                                //
//                                                             `  `` ...-<<<<:;>?z:~~~~.~~.~~~~~~~~~:~:~::~:::~:~~::::::+Zv<:::~~:~::::::;;:::(!.___. `                                                          //
//                                                           ` ...<?<<::~:~:::(<1z<_~~~.~.~~~~::::~:::~:~::~:~:::~:~:(jzIz<:::~::~:~:~~::;;;:<>.```.._<-                                                         //
//                                                         ` .X6_:~::~~~~~~~~~::(<11<_~~~~~~~~~~:::~:~::~::~::~::::(+<<1z;:::~::~::~:::::;;;;+~`.`.```.-<.                                                       //
//                                                       `._!`` <_~~:~~~~~~~~~~~:~::<<<:::(j<::::((::::(-:((+Oc<:<1?<:::<1<:~:~::~::~:~::;>;+>...`.`.```._-                                                      //
//                                                     `.?_.``.`-1::~~~~~~~~~:~~~:~::~::(<1C::::+V1z<<+Zv:::<<1+::(1z<:~::<<_:~:~:~::~:::<>>v~..``.`..`.``(-                                                     //
//                                                     .!.``..`.._z:~~~...~~~~::~::~:::(<<v<:~:(j<<1<:<z>:~:::<1<::(+z_:~::<<<:~::~:~::::>?z<..``.```.`.`. >`                                                    //
//                                                  ` (~``.``.``.`(+::~~~..~~~~::~::~:(<<z<:~::+I::+<:<O>::~:::<1<:~(+z::~::<><::~:::~::<=1>~..`.`..``.`.`.;                                                     //
//                                                   ..`.`..``.``..(o::~~~.~~~:~~:~:~::(+<:~::(+>::<<:<zc:~:~~::<1<:::+<:~:::<<<:~:~::::+=Z<..`.`.``.`.``..(                                                     //
//                                                   <`.`.``..`..`..(c::~~~~~~::~::~:::<v<:~::+z<:::::(zI::~::~:::<::::<::~~:(+<::~::::<zzC_.`.``.`.`.`.```(.                                                    //
//                                                 `._`.``.``.``...._vc::~~~~~~::~::~~(><:~:~(+<:~:~::(1I:~::~:~::<<~~::::~:::<<<::::::+zZ<..`..``.`.`.`.`.(:                                                    //
//                                                  ._.`.`..``.``..._<O+::~~~~~~~:~:::;;::~::<?<::~:~::+O<::~:::~:<<::~~:~::~~:<;:~:::<zw$_...`.`.``.``.`.`(}                                                    //
//                                                  ._`.`.``..`.``.._(+0<:~~~~~~:~:~::;::~:~:<z<:~::~::<z<:~:~:~:::<::::~::~::::;:::::+ldz_..`.`.`..`.``.`.(:                                                    //
//                                                 `(_.`.``.``.`....._<z2::~~~:~~:~:~:::~::::<z<::~::~:<=z::~:~:~::<<:~::~::~:~:::::::+tXy<...`.``.``..``.`-:                                                    //
//                                                  ._`.`..`.``.```..~(+w:::~~~~:~:~:~:~:~:~:+z::~:~:~::+z:::~::~:::<:~:~:~::~:~:::::;zOW>~....`.``.``.`.`..{                                                    //
//                                                  ._.```.``..`.`...~:jv>::~~~~~:~::~::~::~:+z:~::~::~:<?<:~::~:~:~:::~::~:~::~:::::+zwD~~...``..`.`.`.`.`.>`                                                   //
//                                                   _`..``.`.``.``..~~?XI::~~~~~~~~~:~::~:::<<::~::~::~(<<::~::~:~:~~::~::~:~::~::::+lO$~~...`.``.`.``.``. <                                                    //
//                                                   _.``..`.``.`.`..~~;?K<::~~~~~~~~~:~::~::;<::~:~:~:::<;:~:~::~:::~:~:~::::~:::::;+ltC~.....`.``.`.``.`. <                                                    //
//                                                   (-`.``.`..`.`.`.._;;X>::~~~~~~~~~~:~:~~::<:~:::~:~:~(;::~:~::~::~:~~~~~~~:~~~~:;+ltw_~..``.`.`.`..`.`` >                                                    //
//                                                   (_`.``.```.``.`.._:;dI::::~~~~~~~~~:~:::~::~~:~:::~~:<:~~~~~~~~~~~~~~~~~~~~~~~::+=lw<~...``.`.```.``.`.}                                                    //
//                                                   ._.`..`.`.`.``.`._:;j0;;::~~~~~~~~~~~~:~::~~:~~:~~:~~~~~~~~~~~~~~~~~~~~~~~~~~~::<1ld>~..`.`.``..``..`. {                                                    //
//                                                  `.l.```.`.`.`.`.`._:;+S>;::~~~~.~~.~~~~~~~~~~~:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~:~:>=lwI~.`.`.`.`.`.`.``. {                                                    //
//                                                    I.`.``.``.``.`.`._;;dz>;::~~~.~.~.~~~~~~~~~~~~~~~~~~~~~~~~~~~.~~~~~~::~~::~:::;>=lwb_..``.``.``.``.`` :                                                    //
//                                                    (_.`..`.``..``..._:;+0?><:~~~~.~.~...~~~~~~~~~~~~~~~~~:~~~~~~~~~~~~::~::::::::;>?lOR<_..``.`.`.`.`..` :`                                                   //
//                                                    ._`.``.`.`.`.``.._::;Xz?;:~~~~~.~~~~~~~~~~~~~~~~~~~~~~~:::::~:~~::~:(?<~~?1(:::;?ttS<_.`..`.`.`..``.. :                                                    //
//                                                    .>.``.`.`.``..``.._;;dk?<<~~~~~~..~~~~~~~~~~~~~~~~~~~~~:~:~:::::~::<(v<~___?+::<=ltZ<~..`..`.`.`...``.:                                                    //
//                                                     l.`.`.``.`.``.`.._:;jOOz<<~~~~~~~~~.~~~~~~~~~~~~~~:::~~::~:~~:::~(cz>__..-:Gg&>=ltZ<_...`.``.```.``.-:                                                    //
//                                                    `j_.`.`.``.`.``.`._~:j<Sz?<:~~~~~~~~~~~~~~~~~:~::::~:::::~::::~~:(TD+?Tl_7_((>:;=lt0<:....`..`..``.`.(!                                                    //
//                                                     .<.``.`..`.`.`.`.._:j_(Z=<<:~~~~~~~~~~~~~::~::~::~:~~:~~:~~::~::::j<Gz(_..((>;;1tOR:~~...`.`.``..`.`(_                                                    //
//                                                      I_..``.``.``.`.`..~() jzz><:~~~~~:~:~:::~::~::~::~::~::::~~~:~~::<z&vC<<iJC::>1lwb<_...`.`.``.``.`.(`                                                    //
//                                                      (-..`.``.`.`.``...~(\ .k=?<_~::::~:::~:~:~:~~:~~::~::~~:~::::~:~~:~<?1C<<:::;>1ldk$_..`.`.`..`.``.`(                                                     //
//                                                       >..`.`.`.`.`.`.`.~_>  XO?>::~~:~:~~:~:::~::~::~::~~::~::~:~::~:::~::::::::;++z77!....``.``.``..`..(                                                     //
//                                                       <_..`.`.``.``.`...~1` (0=+;<:~~::::~:~:~::::~::~:::~::~::~:~::~:::~::((+<<!_.`.`..`.`..`.``.``.``._                                                     //
//                                                       .>...``.`.`.`.``..~(_ .Sz=+<::::~:~::~:~~:~::~:~~:~:~::~:::::((++??<!~```.`.```.``.``.`...`.`.``..;                                                     //
//                                                        1_...``.`.`.`.`..~(\  WZ==+>;:::~:~::~::~:~::~::::(((:<<<<<!_..`.``.``.`.``..`.`.`..`.``.`.`.`.`(:                                                     //
//                                                        .<....`.``.`.`.`..~j  ,Rll=?;;::::~:~:::::::((<<!~__..`.`.````.`..`.`.`.`.`.`.`.`.``.``.`.`.`.`.(                                                      //
//                                                         1_..`.`.`.``.``..~(;  XZl1z>;::::::(((+<<<~`.``.``.``.`.`..`.```.``.`.`.`.``.``.`.`............:                                                      //
//                                                         ._..`.``.`.`.`...~_z  (Rl==<<<<<<<!!_.``.```.`.`..`.``.``.`.`..``.`.``.``.`.`.`.``.......~_~~_(                                                       //
//                                                          <...`.`.``.`.``.~~(_..T77!_`````````.`..`..`.```.``.`.`.```.``..`.`.`.`.`.`.`.`......~~~_(;:+!                                                       //
//                                                          (~...`.`.`.`....___~_`.``.``...`..`.`.``.``.`..``..`.`.`..``.``.``.`.`.`.``.`..`...~~~(:;;;j\                                                        //
//                                                          (_...``.`.-~~_`.``.`.`..`.`.``.`.`.``.`.`.``.``.`.``.``.``..`.``.`.``.``.`.`...-___(<;;>;+x'                                                         //
//                                                       ` `.___-..-(!..```.........``.`.``.`.`....`..`.`.`.``.``.`.``.``..`.``..`...._~.~~~~::;++++z^                                                           //
//                                                        z<;<v<<~___.``..``........`.`.`..-____~~~~~_-...........``..``.`.......~.~~__-(J+&ewc!                                                                 //
//                                                        .<x+++((c~.`.``.``````.`.`.`..-(js&++++J&&ua&+++&&+JJ(((((-((-((JJJJJ+&dwUW9VTXOllllw,                                                                 //
//                                                           I?zC~..`.`.`...`.`.```.``.(jW90rrtllzzlz=====z1zzz=zOttttOtttttllttttd>+<<__?kOzllw+                                                                //
//                                                          ,<(>.--.`.``.``..`.`.... -(JSttttz11?>><;;;;;;;;;;;;<<<<+11111111==?1z$z<~...(JQslllO<                                                               //
//                                                         `(Z<__J>.....``.``.`....__(ZOll=?1<;;;;:::::::::::::::::::::::<<<<<<<<jcIi,.(r-zHOll==v,                                                              //
//                                                     `  .J>~((<_-__-_...`......__(dZll==<;;;::::::::~:~:~~:~~:~::~::::::~::~::(HDjzY~..(IXllttllv+                                                             //
//                                                      .v<_(+<_~_<jV!.____~~~~_(+d9lll=?>>;;:::::~~~~:~::::~::~:~::~~:~:~::~:~:::?OvIz+(<j0=lttlllv;`                                                           //
//                                                       4++<::(<jZ<~~(+x<~~~_(jV^jlll=?;;;;::::~:::::::~~::~:::~:~::~:~::~::~:~~::(?OVOOC1?===Otlllv<                                                           //
//                                                        U<:::jX>~~_+H8<~~~~(Z!`.(Zz?>;;;:::::~:~:~:~:~::~~:~:::~:~::~:~~:~::~::~:::::;;>???===llll=vl`                                                         //
//                                                                                                                                                                                                               //
//                                                                                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SWEETDEVIL is ERC721Creator {
    constructor() ERC721Creator("SWEET DEVIL", "SWEETDEVIL") {}
}