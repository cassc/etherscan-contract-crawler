// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FUZZ_GAFFcartoon_mini
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                       //
//                                                                                       //
//                                                                                       //
//                                                                                       //
//                                    .-#UU&..                                           //
//                               `..g9ldIllzluvQe0C(..      .~?-.                        //
//        `  `  `  `  `  `  ` .,"=J9&ZUKlzluZdBwNbd8HojN-,. Z...y    `  `  `  `  `       //
//                        .,7~..(B9IlzlvTQZdNNgNyHW8d#! .NzT<<+d\                        //
//                     .?~.....([?"=wezlJ:(:::?VUJdY_bJ"7MND>(zHHN                 `     //
//       `           .+-.....--(b-Hk(..,Y=<+<:?VdkY=7Bn...M<<zdHd?p.                     //
//          `  `  `   .9...-~~~~TYMHWQkWL(::::?THNn...y^~?E4&7` _.F<?"=..  `  `          //
//                 .(^...-~~(jD:J.(ZyWHHN+++:::?m, ?7dHn..W?   .XY4.(7T91(...    `       //
//                 j-..._~(M{,z"?].KMMHyUXAZTJx<WkyHS&..?B   .XY` J-........._71,        //
//       `         J.--?1JJ?     u 4UNkZyZyZWHX&dHHHHHQX[,..XY   `(r~~_-.`....-(J        //
//          `  ` ,^-(=    5... ."?;-kNykQQQXyZX#HXZZZyWHHW#47?5   _Ng&+JJ.-`.-J^         //
//            .,!-(J' .e.  G,t?J,_b HdWWdQMyMHy#ZyXZyZZyS ]...,`  ~N  ,^....(TH,         //
//          .(-JXx?"?` JN..(7mT:_(d.dXkXkyWWMWyNdNMKNHMWU.j ..u.` ~W  =,.`.._~(7    `    //
//       ` ,((wkHb.?777H8,  .hJ"' .bdNYYNHNXZZZyyWWHNUHZy], (.....-d..T"_.-(J=           //
//               ,!... `J; `(     -PHM..M,?WQkkXWNWWNHMmXb.{ ^ MmHf_-JJJJJ"              //
//              r  ` .4,~P  (    .M%?WhdMN.Mp (N..N. (NUNW [  `?HmdMMHHMN,               //
//             .  ..  .dJ'  JT] .HM``,HHNMMMMNMMNMMR.MMNdM_t  .7<(_Jr"NNmHN.      `      //
//             .L  HT~_d` ` ^ [email protected] ..MHWWHMMHkHMMMMMMMF.7 (,.7G+z~Ji?""9NM\             //
//              ,N,,=7=` .!  .MmmH] -NfpHMHfWMpWkkH%WMM!!  ,J(uJCj(b5<_  .b              //
//                 ?7"""?WBv=7"BHM` NWMWHWkWMHWHNNF .7<!, .%;(KTHY!    `.JJ              //
//                              .,[email protected]?(...=(J` /,.%.= .7 .   `J:              //
//                           .,=_.-(HWWWHffpkM5_    `    ,.(MY  ,? <~    J}              //
//                         .<..--~(MMpHpWHHkMNJ,  `     .$(T^  `   !   `.g!              //
//                         7,._(JdMHHNkWNpWMl  .MMa...`[email protected](^   ..,     `-(F               //
//                         .#--4.  [email protected]^ ?""j  `JbF  ` ,  .b                //
//                      .,=((?!     .HXMMMNfWHmmMb   ..   [  (F  `.Mm` `_?Y,             //
//                    ,7?!          ,RZZZXffWMNHqmMMNKHMm ,--(9+..~~(S.._~~J             //
//                            .dBWWHMMMMMMHfffWMMNNNMWffMN,      ?"Y7'                   //
//                          .SvvvwZZZWffpffffffNXZZZZXffMfWh                             //
//                          KXwwZZuZZZXfffWkHMMMMNNHHHffpffWL                            //
//                          WkZZZZZuZZXfWMUzXXZXWfWMffffffffK                            //
//                           HNkZuZZZXfWHzvvwXZZZXffffpffpWM#                            //
//                            ?MMMMMMMMMZZXZZZZuZZXfffffpHMM"                            //
//                                ```` ,NZZZZuZZZZXffpfWM#^                  .-.-((-,    //
//                                      ,NmXZZZZuZWffWMMY                    (PII,_%}    //
//                                        ?WMHmmmQHMMMY!                     (+,+jxa}    //
//                                            _?77?`                         (dnX(=P}    //
//                                                                           .!!!!!!!    //
//                                                                                       //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////


contract FUZZGAFF is ERC721Creator {
    constructor() ERC721Creator("FUZZ_GAFFcartoon_mini", "FUZZGAFF") {}
}