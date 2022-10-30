// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KEKDROP
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                             //
//                                                                                                                             //
//                            .'cccdko;::.             .'''..''..........                                                      //
//                            .',,,,;;:c;.     ..''',,'''...'::'..';:ccllcc,...                                                //
//                            .'',,,',;,...''':dOkkOKkc'..'..:dl;,:okOOOOOKkoc::'.                                             //
//                           .'clc:;,,;,..;:;;oOK00XXx,..;c;..',,,codOXNNXXXKkdxxd:'. ..                                       //
//                          ..;:;,',;;:odoloollxOkOXKk:. .:l:,....:xkk0XNNNXKOkOKKkdoldxdc,...                                 //
//                         .',;;;;ccccoO0OxdkxokKXXNNKd;...:llc,'...cdx0XNNNK00KXXXKKKKXNX0xc.   ....                          //
//                      ..',,;;cx0XXKklldxxk0kk0OkkOKK0x:..,::cllc;...'lKNNN0OO0XNNNNX00XNWNO;. .;cll;'''.                     //
//                    .'',,,'.;xXNWXOdddxOKKXK0OdclOXXKKO;..;clllllc:'..lOKOdoolxXNNNNXKXXXKx;. .,lkK0kol:'''.                 //
//               ......,,:ll;':ONXKOxx0KKKK0000Odox0XXKXKd...:llllllc,. .;c;'...;d0XXX0xl:;'.... ..:dO0kdc::;,...              //
//             .,:ldddoolllooclkOxxOOO00K0OOkxdxkOKX0OOOOx:. .;looc,.  .,:cc:;''..,::,'......,::'..,lxxo;;cc:;'...             //
//           ..';cdk0KXKOxlldkOkoldxoxO0000Kkoccloxxl:::;;'. .';;'.  ..,:lllcllc,...;:cccc:;;:;'. .'odl::cddxdc',;'.           //
//         .,:cclllx0XKklccoOXXKkolllokOOkddo:,..,;;,'..  ..      ..,:c:cllllccc' .,cooooc;'..  .':dOd:;cdxxkOO0kddl,          //
//      ..';cododoldkkOOxookXXKOOOOkdooolc;,''.  ......   ..   ..':llllc:cc:;',,. .'clll:'.   .':dO0Od:,;ccoOXXXOkK0o'.        //
//     .',:lxkdcccclccx000OKNX0kxxolccc;''....              .,;:cllllllc;;::;;;;.  'c:,..  ..';;cooooc,'',;cx0K0ddkxl;'.       //
//     .,;cdOkxxO00OdldOO00OO00kl,''.........             .,clllllllllllcccclll:.  ...    ....';:::;;,...',;:lolc::;;,,.       //
//     .,;cdkO0XNNNKxcclxkdc:cl:,...                    .,:ccccllllllllllllllllc,     ..       ..''...  .........',;;'...      //
//    .';::lodkKNXKOdl;,;c:,''..........      ....      ...........',;:cllllllll:'.. .'.                         ..','.'.      //
//    .';:lxxlldkkdl:;,,''.....     ...........'..  ..''...........   ...',:clllllc'      ...  ....             ..',,,,'.      //
//     .'cOKOo::::;,.......    ...............    .,cllllllllllllcc:;'........,:cll,    .',,'......         ....''''...        //
//     .:x0KOoc;,'.....        ..''...........   .:llllcclooolclllllcclc::;'.. ..,:,.   .........     ....  .'''...            //
//     .;cddolc;,'..            ..........'..   .:llllc::looolcclodo:;:;;:clc:,.....     .  ....    ..''.. ..,'..              //
//      ..,;;::::;,'..   ......... ........   .,clllll:,,:cc:::codkd:,'.':ccllllc:,.     ..........'',,'......                 //
//        ....','..''......''''''.........   .:lllllll:'.':oxOOkkkkkkxl,';clcccclllc:'    ...'''',,,,''..                      //
//                  ....   ..  ..''.......  'clllllcc;,,cx0XNX0o;'..':oo;..;c:::llllc;.      ......                            //
//                                  .''.   'clllc:;'..:kXXXNNXO:....  .;c:...,,;cllc:'.                                        //
//                                   ..  .,clcc;,'...:0XXXXNNX0:.. ..;lxOk:..';:ccllc'                                         //
//                                       .cccc:;,,..,ooc:lodkOo'...lO0OOKKk,..;:ccclc'                                         //
//                                       'cllcccc:'.ll.    .,oo;,,:dOK000X0l..;cllllc.                                         //
//                                      'cllccccc:'.:d,   .,d0XXKOc'',;cxKKd'.:ccccl:.                                         //
//                                     'clc:cllllcc,.;l:,:oOXXXXN0c     .cdl..;cc:cl;.                                         //
//                                   .;ll:;:clllllc:'.:k0XXXXNXNNXo.     .....;lllll:.                                         //
//                                  .;llc::clcccc:;;,,',:ok0XXNNNXk;.','....,cllllll;.                                         //
//                                  ':llllllllclccccc:;,,;;clxkkkkxl:;;,,,:clllllllc,                                          //
//                                 .;clc:;,,,,,,,'''',,;;;:::cc::;;;;;:clllllllllllc'...                                       //
//                                .','..                   ...,::clllllllllllllllll;....      ...                              //
//                                         .......''...'.....    ..';:clllllllllllc.                  .........                //
//                                 ......''',,;,,',''',;:::c::;,'..  ..'clllllllll;.                       .                   //
//                              ..;c:,',''',;,,,,,;;;;;;;;:looollc;;,.  .;lllllllc.           ..                               //
//                             .;cl:'.....',;;;;;,,,,,,,,;:llllllllllc;. ..:llllc'             .....                           //
//                             ,llc,.  .............'',;:::cllcclllllllc'. .,cll:.          ..........                         //
//                            .';'..            .      .....',,;ccllllllc,.  .:c'              ......... .                     //
//                                  ..''''''',;:;'..'''...  ......,;:cccc:;'. ...         .......... .......                   //
//                                .;cllllcccllll:;:cllllc;..,'''''...,cccllc;.           ............    ....                  //
//                               .;lodddddollcccccccllllc;',;,,''''''.':cccc:.          ...........                            //
//                               .cx0Oxdx0XKklllc:;;:llc:;',;;,....','.';:ccc'            .........                            //
//                               'dK0l'..,xXXkoc::cllllllcc:,;;;;,''',,.'cooc'   .'....     .......                            //
//                               ,k0o,....;OXkolllllllllllll:,',;;;,'',,,;clc'  .;:;;;'..        .                        .    //
//                               .dKo'....,oo:;:;;:ccccccllooc:;,,,;;,',,',:,. 'oOxl::::;'....                    ....  ...    //
//    ...........      ...........;k0o;,;:;..      ....,:clllllllc,',;,'....  .,oxoccclcclxkdl;,,'..     ..................    //
//    ................',;:c::;;;;;',oOOkdc'.',;;,...    .;llllcoddl,.,;,...  .';:ccccllllx0XXKKOd:'.......'''.         .  .    //
//    ............',;;;;;::::::::::,'.'..  .,:::ccc:'..  'clllllooc'.',,....';ccllllolccclodkKNXxc;;;,'''..',,....    .....    //
//    ..............'''..',,;,,;;;;;;'..    ...''',;:;'. .,ccc:;;,...',,'''';:cloollc;;;:;;:cdxo:;;;;;;,,,,'''''..  .......    //
//    ...............       .....',,,;;,'..   .''.. ...   ......   ..,;;;;;,;;::ccc::::::;;;;;;,''''..'.....           ....    //
//    ..............               .......''.......        .......',;;;:;;;;;;;:::;;;;;;,'''....                      .....    //
//    ..............                      .,'..'''........',;;;;;;;::;;;;;;,;;:;;;;;;,''....                           .       //
//                                                                                                                             //
//                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract KDROP is ERC1155Creator {
    constructor() ERC1155Creator() {}
}