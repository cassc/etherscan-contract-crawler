// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: billyrestey editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    .............................  .                                                                                            //
//    ...........................                                                                                                 //
//    ..........................                                                                                                  //
//    .........................             .                      ...                     .,::::::;'.   .;:::::;,.               //
//    .......................               ..                   ....                      '0MWXKKXNXk,  :NMNXXXNNXx'             //
//    ......................           .                                                   '0MO,..'xWWo. cNMk,.''dNMx.            //
//    .....................            .. ..                                               '0MXxddxKWO'  cNMk,.',dNWd.            //
//    ...................                ...                                      ....     ,0MXkdxxOXKo. cNMWXXXNWKo.             //
//    ..................           .     ....          ......      ..       . .........  . ,0MO,...,OMN: cNMO::xNWx.              //
//    ..................  ... .    ...... ..          .. ....        .      . ......'..... ,0MNK000XWXd' cNMx. .lXWO;             //
//    ..........................  ....               ..              ...  ................ .:llllllc:'.  'cl,.  .,cc;.            //
//    ......''..................                   ....              .......','...................................                //
//    ......''''................               .......        .       .......''..........................................         //
//    ..''',,,,,,,,,,,,''....                ..''....                   .....',,,,;;;;;;;;;;;;;;;;;;;,,,,,,,,,,,,,'''......       //
//    .'',,;loooooooooollc'.                .....'..              .       ..,:lloooddddddddddddddddddooooooooooooolllcc;'...      //
//    .'',,cOKKKKKKKKKKK0o'.                  .....              .....      .:x0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0KOc....     //
//    ..'''ck00000000000x;.                    ...               ...'.       .,d0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKOc'...     //
//    .....';::cccllllcc:'.             ...     ..              ..'...        .'cooodddddddddddddddddddddddooooooooollc:,....     //
//    .......''',,,,,,,,,..                     .              ......          ..,:::::ccc:::::::::::::::;;;;;;;;,,,''......      //
//    ...........'''''.''.                                     ..',,,.           .';;;,;:::;;;;;;;;;;;,,,,,'''''''.........       //
//    ........''',,,'''',.                                    .',;:cl,.           ..,;;;;:c::::::::::;;;;;;;;,,,,,'''.......      //
//    .....',;::::c::::;;.                                    ';:ccooc;.   ..      ..,:lllllllllllllllllllllllccccc::;,'.....     //
//    ....'cxOOOOOOOOOOOo'                                    .;lddkx:'....''.      .,cxO00OOOOOOOOOOOOOOOOOOOOOOOOOkkkx:'...     //
//    ....'l0XKKKKKKKKX0l..      ':.                           .,oxOKKOOOkkkkl.     .,oOKXKKKKKKKKKKKKKKKKKKKKKKKKKKKKXKl'....    //
//    ....';oddxxxxxxxdo;..      'c.                             ;dxkxxxdddddo:..    .lxxkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxd:....     //
//    ......'',,;;;;;,,,..       ...                             .,ll::::::ll:;;'.....,:::ccccllllcccccccccccc:::::;;,''.....     //
//    .........'''''''''.        ....                            .';;,;;;;;::;,,,,,,,,,;;;;;:::::::;;;;;;;;,,,,'''''........      //
//    .........''''''.''.       .''''..                          '::,,;;;;;::;;;;;;;;;;;;;;;;;;;;;;;;;;;;,,,,,'''''.........      //
//    ......'',,;;;,,,,'.      .'','...            ...   ........;lc;::ccccccccccccccccccccccccccccccccccc::::::;;;;,,'......     //
//    ....';lodddddddl:,.. .  ...''..   .....      .',....,,'..,,,,cdxxxxxxxkkkkxxkxxxkxxxxxxxxxxxxxxxxxxxxxxxxxxddddool;....     //
//    ....,oKXKKKKKKKOo;''.....     ..........      .',....','',;cco0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKo..       //
//    ....'lkOOO00OOOOd:,';:'';.                     .......'',',lxkO00000000000000000000000000000000000000000000000000Ol'..      //
//    .....';;::ccc:::;,'..;:;;,.                      .....',,';dkkdclloooooooooooooooooooooooooooooooooooollllllllcc:;'...      //
//    .......'''',,''''....';;''..                        ..',,;cxOkl;;;:::::::::::::::::::::::::;;;;;;;;;,,,,,,,,,,''......      //
//    ...........''..''.....,,'...                        ...,cc:odxl',,,,;;;;;;;;;;;;;;,,,,,,,,,,,''''''''''''............       //
//    .......'''''''',,.....,;..                      .......;:,;ccoo;,;;;;;;::;;:;;;;;;;;;;;;;;;;;;;,,,,,,,,,,,'''''.......      //
//    .....';;:::::::::'...',:;'''.  ........        ...''...',',;;:llcccllllllllllllllllllllllllllllllllcccccccccc::;;,'...      //
//    ....'lOOOOOOOOOOx;'..';oOOOOo.  ...  ....           ....,,',;:oO0O0000000000000000000000000000000000OOOOOOOOOOOOOkl...      //
//    ....'oKKKKKKKKKXOc''.';xKXXXx.   ..... ..       .'.  ...''''';d0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKKKKKKKKKKXKd'..      //
//    .....;loodddddddo:'...,ldddo:.    .......        ........',,;:dkddkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxddo:...      //
//     ......''',,,,,'''....,;''''..     .......       .'. ...',;:::lxc';:cccccccccccccccccccccccccccc::::::;;;;;;;,,,'....       //
//      ................'. .,:,....'.    ...''''.          ..',;:ccclxo,'';;;;;;;;;;;;;;;;;;'.................................    //
//          ..............  .,;;;;;,'.   ..',;;;.          ..';:cloodxxc;,',;;;;;;;;;;;;;;;,..................................    //
//                  .......   .cdxc'......',:cl:.............,:loodxkO0xlcc::ccccccccccccccc;;;,,,,,''''......................    //
//                ..''''',''..,lx0Ol:c:::cloxkkolllodlclllllloxkO00KXXXX0OOOkxkOOOOOOOOOOOOd.                     ...;;;::::cc    //
//               .............';;::,'''''',,coollccll;;:::::::coxOO0KKKKKkxkkxddxxxxxxxxxxko.                      ...''''',,,    //
//              ....'''',,,;,,cl:,::,,,;;;::cdxkkxdolcccllllllldxOO0KKKKK0kkkkkxxkkkkkkkkkko.                      ..',,,,;;;;    //
//              ....,,,,,;;;;;ldolllc:cclllooxOO00xodkkdddddddddxOO00KKKXX000000OkOOOO000O0d.                      ..;:::::ccc    //
//                 ...........,:;;''....''',;ldxOklcoxdl::::::::codxkkO0KKkxxxxxxdoodxxxxxxo.                       ..........    //
//                ..''''''''',lkxxdollllllloxkO0K0kkO00OkxddddxxxkkO00KKKXK00000000OOO00000k,                       .,:::::ccl    //
//                 ...........;lllllccooc:::ldxkOOkkkxxxxdlcccclllloxkkO0KKkxxxxxxxxdodxxxxd:.                      .....'''''    //
//                 ...........,clcllllodoc::lodxOkxkxdddddoc::cccccloxkkO00koddddoooolloooooo,                        .......'    //
//                 ...........,clllllllodolcoxxkxdxkxddddddolccllccldxxkOO0Oddddddddddoooddoo;.                      ..'''',,,    //
//                         ............',,..';:c;'cdc,,,,,,,'......';;:coxkx:,,,,,,,,,,'',,,,..                                   //
//                  ...........';::::::cllc;;clo::ldocccccccccccc::cclodxOOOdccccccccccc:cccc:'.                       .......    //
//                          ............;;;,..,'..'cc,'''''''''''''''',:oxddd;.'''''''''..''''...                                 //
//                                      .',,.     .;,..........  ....   .;ldd;,;.... .     .....                                  //
//                                      ..'.     .',. .,;.         .      'dk:,xx'                                                //
//                                       ...     ..'';cc:.                 ;xl.'xo.                                               //
//                                       ...      ..',lol;.                .cd,.cd'                                               //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BRED is ERC1155Creator {
    constructor() ERC1155Creator() {}
}