// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Intel x JP the Money Bear
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    0000000000000000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    000000000000000000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    00000000000000000000000OOOO0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    000000000000000000000000OxdollcloxOOOOOOOOOOOOOOOOOOOOOOOOOkxdoooolloxkOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    0000000000000000000000Odc,.......,cdkOOOOOOkxkkkdl:okkxdkkdc,'.......,:dkOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    000000000000000000000Oo,...........';oxkdl;'.,;'....,'.'::,............,dOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    000000000000000000000Oo,.............';:'..........    ';:;'............lkOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    0000000000000000000000x:',;,.....'...'''''''.'''.......,clc,'...........:xOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    0000000000000000000000Odlll;....'...'''...';;,;,,''.....,,,,;,'........,okOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    0000000000000000000000000Okdl;'....,,'.',;;;;;,,;;,,'''','.':clc,....;lxOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    00000000000000000000000000000Ox;..,:,.';,;lool,.;;''''..''';lccll;..ckOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    000000000000000000000000000000kc.'l:',;;,;lddl,','...'....',;:::cc;.;dOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    00000000000000000000000000000Oo'.co;,;;,cool:;,,''''''.''...',,,,;,..,okOOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    00000000000000000000000000000x:..cc,';;.';;,''',,'..............'''....lkOOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    0000000000000000000000000000xc..':;,'',''''''';:;;;;;;'.............''..:xOOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    000000000000000000000000000xc. .,:;;,,''...';:;;;;;;::,.........    ..   ;xOOOOOOOOOOOOOOOOOOOOOOOOO    //
//    00000000000000000000000000xc.  .,::::cc;,',;::;:;,,'..............        ;xOOOOOOOOOOOOOOOOOOOOOOOO    //
//    000000000000000000000000Oxc.   ..,;:c:,'';::::;,'...................      .:xOOOOOOOOOOOOOOOOOOOOOOO    //
//    00000000000000000000000Od:.    ....'..',;;;,,'.....................''.     .ckOOOOOOOOOOOOOOOOOOOOOO    //
//    0000000000000000000000Od;.    ...    .....''......................'',,..    .ckOOOOOOOOOOOOOOOOOOOOO    //
//    000000000000000000000kl,.    .....     ....    ..................''',,'....  .ckOOOOOOOOOOOOOOOOOOOO    //
//    0000000000000000000Ox:............                    .............''..  ...  .lOOOOOOOOOOOOOOOOOOOO    //
//    000000000000000000Od;........                           ......'....       ...':dOOOOOOOOOOOOOOOOOOOO    //
//    000000000000000000Oo;'........ .                 ......   ......          .'':xOOOOOOOOOOOOOOOOOOOOO    //
//    0000000000000000000Okdc,.......';'.               .           .          .;,;dOOOOOOOOOOOOOOOOOOOOOO    //
//    0000000000000000000000Okdl:'....;ol'              .                     .,::okOOOOOOOOOOOOOOOOOOOOOO    //
//    00000000000000000000000000Oxl;'..;l;',..                      .    ..;lc'':okOOOOOOOOOOOOOOOOOOOOOOO    //
//    00000000000000000000000000000Odc,.,,,:;'......   .            . ..'cllodl:lkOOOOOOOOOOOOOOOOOOOOOOOO    //
//    0000000000000000000000O000OOkdo:'.....''',,;;;;,'.            ..'cddc,..,;lxxxOOOOOOOOOOOOOOOOOOOOOO    //
//    00000000000000000000O0OkkOkxo:.         .';::cloolc:'          ,dxoc;.  ..':ldkdokOOOOOOOOOOOOOOOOOO    //
//    0000000000000000000Okkkoc:;:od:.   ..    ....,;:lodddc'.      ,ooc;'.    ..',lko',okOOOOOOOOOOOOOOOO    //
//    OOOOOOOO00OOOOOOOOxl;,cdol;;x0O:. ..'....... ....',;;::'..   .,;,......   ...;xo...;dkOOOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOOOxc'...':kKOldKKd,..'',,'.. ....................''..'....   ..,od,...'okkOOOOOOOOOOOO    //
//    OOOOOOOOOOOOOOxc'. .''.'ckXOoOKkc;::,'''.  .,;.''........  .......'''''..  ..,od;.....okkOOOkkOOOOOO    //
//    OOOOOOOOOOOOxc,. ..... ..;dOodOkc;oxlcll:;;:oc..''''..... .......'''''''.. ..'cl,'....'okOkkOOkkkkkk    //
//    OOOOOOOOOOkl,.. ...    ...;lccdd;.cdcloclo::o;.','''............'''''''''.  ..',.......'okkOkkOkkkkk    //
//    OOOOOOOOOx:..  ...     ....,,:do' '::cc:c:.,dl;cddddl,..........,,'''''''........  .....'lkkkkOkkkkk    //
//    OOOOOOOOd,.    ..     .....,,cxl. .;lllll;.lkdkOdc:lxc..........'..''''''''.....   .......:xkkkkkkkk    //
//    OOOOOOOo'.    ..      .....;;lkc. .c:.'';lolck0l,:coo;'............'''''''''...     .......'lkOkkkkk    //
//    OOOOOkl'. ..  ...     ... ,c:cc'.  ,c:;'.:l.'x0xoll:'''..............'''''.....      ...''...:xkkkkk    //
//    OOOOx:....'''.''..    .   ';,,..    ...  .. ..;;,...','.....  ........''''... .     ......''..;dkkkk    //
//    OOOx;.  ..'',;'...   .     ......              .....','................'''''..         ....''..,dkkO    //
//    Oko;..........'''.         .......              .......................''''....       .......'..,dkk    //
//    Od,..',,,'.   .'...         .'....                   ...................''......     .....  .''..:xO    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract IJPMB is ERC1155Creator {
    constructor() ERC1155Creator("Intel x JP the Money Bear", "IJPMB") {}
}