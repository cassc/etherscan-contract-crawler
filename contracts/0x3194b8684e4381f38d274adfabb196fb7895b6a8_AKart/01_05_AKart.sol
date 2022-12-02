// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Artistken
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                       ...... .....                                                             //
//                                                  ..',:ccccc::;,,'...........                                                   //
//                                            .;coxO0KNNWMWWWWWNXKK0Okdl:;'........                                               //
//                                        .;oOKWMMMMMMMMMMWWNXXXNWWWNXKXNKxl:;,''......                                           //
//                                     .cxKWMMMMWWNNNNNXXWMMWNK000O0XNX000000kddc,'..,'.......                                    //
//                                  .;xXMMMMMMMWWWNXXXX0OOOkkOXWWXK0OkOKWN0O000Okdo:'.,,'........                                 //
//                                .lOWMMMMMMMMMWWXXXXNWMMMWXOkddx0XNMN0kxONWKkkKX0xxxc;'...............                           //
//                              .cKWMMMMWNK00OOkkddddxkkxxx0XWWXkocldkXMKdlkNWKxkXNkx0Ooc'............''..                        //
//                            .:OWMMMWXKKKKXXWMMMMMMMWNKkoldOXWMMNXkc;lOWM0c:OWNko0WKdk0xl;..',,........','..                     //
//                           'xWMMMMWNXNWMMWNXX0Ok0XWMMMMNOxk0KWWWWW0loxKWMXc'c0WOckWXdxKOo:'..,;'........,,'.                    //
//                         .cKMMMMMMMMWXOkxdoooodxk0KXNWWWWKdclx0XNWWk:l0WNW0:,cKMk;dWNddKkol;...,,....'''..''.                   //
//                        .xWMMMWMMWKxoodkO0KKXK0kdllox0XKXXxccdkkxKNxc;lOXWNl:dOWWl.oXXooKklc:'..',.....''......                 //
//                       ,0WMMWMWXOxxkOKXNNNNNWWWWNOllodOxOkc::lodxxd:,,oxON0:.dNNWO'.lNk:dKd:l:.. ';'.','..;;.  .                //
//                      cXWWMMWXOdkKXXOxdOXNNXKXNXXKocclooo::;,;cc::;'.,codd:';ckXNO;.:KX:;OOlco,.. ':,.',,..';;..                //
//                    .oNWWWMNKO0XNN0dlcdkOxolloxkOOlcc::;,,;'..'',,,'.',;'...:oxXXl'cdKWc.l0d;lc,.. 'c;..';'.';:;'.              //
//                   .oNWNWNK00KXXOoc:coolllllllooddccc;''''.......... .......;ldxc..kX00: ;Okclc,'.  ;l,'.':,..,,,,'             //
//                  .dNNNXK0OO0K0dcllodxxxkxdl:cdlcccc;'....    .....'..    ...''...'dO0x. 'Ox;;:;'.  .:c;;'';:'..'',.            //
//                 .oNNNX0OOOOxolloxxxkO0KOxxl:ldl;:;,...            .',,'.    .. .;lkKx,..l0c.;l;..   'lccc,':c,.....            //
//                .oNNNX0OOOkl;:lodxxdxkkdodoc:ld:,'..           ...''''.';;.    .';cl:..odxo. ;l'.'.   co:cl,,:c:.  .            //
//               .lKXXKOOOkxlcloddx00koc::ccc:;ll,'..            ....,,,;,':o;    ...  .lkkd, .c:....   ;xl,:l,,::c'              //
//               l00OOOOOkolllodllkOdc;;;;cc:;:l;'..           .;,,:lcc;,;,,ckc      ..cxxo' .;c'.'.    .dd:;cl'';:l:.            //
//              :00Okxkkdoolodoc;lol:c::::clc;:c,..          .'cOOkkkkOOd:;cokO,     .;c:'...;:...'.    .ooc;;c:.';;lc.           //
//             'k0Okxxxooolokd:;;,;;;:::;;;cl:;;'.           ,dKWX0kkxoOXOookONl         .,:l:. ...     .lol:;:l;.,;;cc,.         //
//            .x0xxxdolooldxocc:;;coddoocc::ll;'.           .dNWXo,o0o.;0N0k0XWo       ..:o:'  ...      ,xdlc;,co,.',;:l;         //
//           .o0kddoololcooccc,,:clodlccodcccc;'.           .kMMK:.lO: ;XWKKXWN:      ..''.   ..        :kd:ol':ol...',;:.        //
//           :0Oxddollccol::;;::;,;cc;;,;c:;:;,..           .xMMWkclo:cKMWNNWWx.           ....        .oxo:oo';lo:....''         //
//          'xOxdddolcllc:;,:cc:::;;,,;;;;:;,,'..            ;XMMWNX0KWMMWWMWx.         .....          ;xl::lo';llo, ..,.         //
//         .lxoooooocllc;;,:c::ccc:,,,',;:::;,,..             ;OWMMMMMMMMMW0c.                        .ddc::lc';llxl. ...         //
//         :dolllooccl:::;;:cc;:ll:,'''.',coc;,'.              .;dkOKXX0kl,.                         .ldol:clc',::dxc.            //
//        .clllclllclc:c:;;:c;,:c;'......';ldl;,.                   ....                            .odloo:cdo'.:;lxd;.           //
//       .;cccccllcc::c:;,:c:;:;'..,;;;:clc:cc;,'.                                                 .colcdo;cdd,.,,:lol'.          //
//       ,:::::cc::::::,,;cc;c:..;c::;,,;cc;',,,'..     ...                                       ,lc::ox::dxk:..',:cl:'          //
//      .;:::::c::;:::,';:;;;,..::..',,,;:;,'...    .;lkKNx.                                    .;cc;;ldl,ckxd:..,,':;;c.         //
//     .':c::::::;;::;,,;,'',..,,...'''''...   .,cdOXWMMW0;                                   .'::::;coo;'lxko,. .o:,;',,         //
//     .,:::;;;;;,;::,'''..'...........   .,:okKX00NMMMXd.         .;x0x'                   ..,;;::::oxl',coxd;.  ,xc':,.         //
//    .',;;;;;;;;,;;,'''..''.        .,cokKXKOd:;ckNW0l.       .;dk0WXk;.                 .';;,,;:;;cdd,.,;coo;.   .l:''.         //
//    .,,;;;;;;,,;;,''''..'.  .,,:ldkKX0ko:'. .cONNk:.      .:xKNKOxc.                ..',,,,,,:c,,:ox:..',cll,...   ',.          //
//    .,;;;;;,,',;,''.''..'. .oXXKOdl;'.    ,dXW0o'     .,lOXXkl;.                 .';::;,,,';cc,':ldo. ','ccc:....               //
//    .,;::;,,'',;,'.'''.';.   .'.       .lONNx:.    ':xKX0d:.   .....     ......',::;,,;;,,:l:'':llo:. 'o;:;,c,....              //
//    .',;;;,,'',,''.''..','.... ...  .;xXW0o'   .;oOXKkl,.  ..',,,,,,'',,'''..   ..'::;,;cll;'',clo:.. .xl,:,;'.'...             //
//    ...',,''''''.'.''...,'.....   .lONXx;.  'cxKN0d;.    .,;;,,'''''''..   .,::;.  .,,:odl'.'';lol,.   cd',;....,..             //
//    '....'..''...'......;,..   .;xXN0l' .,oOXXkl,.  .','''',;:::::;'.   'lkXNXXWXc  .:dxc. .,':clc...  .l:...  ..'.             //
//    .............'......'.   'l0WXx;..:dKNKxc.      ';,,;:cloddoc;.  .cONNOdclkNNd. .ld;.  ,,,:,l: ..   ..                      //
//    ...................   .;xXW0l'.:xXWXx:.   ..,:c;.  .;loc:;'.   ,xXWMWOdx0NXk:.  ..  ..  .,'.'.  ..,;.                       //
//    ................    .l0WNk:';dKWXx:. .':ox0XXNWMX:  .;,.    .,kNMMMMMWKko:.     .;lx0Ko.    .;lk0XWWNl                      //
//    ...............   ,dXWKd::dKWXxc'':okKXKOdc;'oNMK,  .'.  :xOKNMWNKko:,.     .;okXWMMW0:.':dOXNKk0WMW0;                      //
//    ............   .;kNWOl:lONMWOood0XXOdc'.    'OMNo  ..    cXMMMKl..     .,cdOXN00NMMMW0x0NXOd:,;oKWXo.  .                    //
//    '.........   .cONNk;'oXMMMMWNNXko:.   ..   ;0WNo. ...    '0MMNc   .':okKNX0dc'.oNMMMMW0d:.  .lKWXo.   .,,'.                 //
//    ,''.....   .oKWXx,  .oKNNKOdc,.      ..  .oXMK:   ':.    ,KMMNkoxOKNNKxl;.    .xXX0xc,.    .kWNx'           ..';:ldl.       //
//    ,,'''..  .oXWXd'      ....      .  .    ,OWNx'   .';.     ;k0KKK0ko:'.         ....        ;XMKc....',:cloxO0OOOxoc,        //
//    ,,,,.  .lKMXd'  .....         ....    .oXW0:    ...:'       .....        .          .;'     cOXXXXKKKK0kxol:,..             //
//    ;;,.  ,OWWk,  .'''...............   .:0WXo.    ....;:.             ',    .           .;c;.    .',,'....                     //
//    ;,.  :XMXl.  .',,'.............    ;kNNk,      .....c:         ..  .;;.              ...:c;'..                              //
//    ;.  :XM0;       .''...........   'xNWO;    ..    ....:;.        .....;:'                 ........                           //
//    ;. .xMMk'.':oc.  .'''''''''..  .oKW0c.   ......   .  .''.        . ...'::'                                                  //
//    ;.  ,0WWXKKOo,  .'''''',,..  .lKWKl.   .........   ..  ....            ..,'.                                                //
//    ,'.  .:oo:.   ..,,,,,,'..  .l0WKl.   .............       .....             ....                                             //
//    ;,,'..    ...,;;;;;;,'.  .l0NKo.  ..................       .....                                                            //
//    ;;;,,,,,,,;;;;;;;;;'.  .l0WKo.  .',,,................           .                                                           //
//    ;;;;;;;;;;;;;;;;;'.  .l0WKo.  ..,;;,,,''...............                                                                     //
//    ;;;;;;;;;;;;;;;'.  .lKWKo.  ..,,,,,;,,,,''''''.............                                                                 //
//    ;;;;;;;;;;;;,..  ,dXW0l.  .',;,,,,'',;,,,,''''''''............                                                              //
//    ;;;;;,,,,;,.   ,xXWOc.  ..,,,;;;,,,,,,,;;,,,,,''''''..............                                                          //
//    ,;;;;;;,'.  .;kNNO:.  .,;,,,,,,;;;,,,,,,,,,,;;,,,'''''..................                                       .........    //
//    ;,;;;;,.  .:ONWKc   .,;;;,,,,;;,,,,,;;;,,,,;;;;;,,,,''''''........................            ..........................    //
//    ;;;;;;.  :ONWWNl  .',,;;;,,;;;;;;,;;;;;;;;;;;;;;;;;;,,''''''''''....................................................''''    //
//    ;;;,,,.  ,xOko,  .,;;;;;;;;;::::;;;;;;::::;;;;;;:::;;;,,,,,'''',,''''.............................''''''......''''',,,,,    //
//    c::;;;;..      .';::::::::;;;:::::::;;;:::::;;;;;::::;;;;;,,,;;;,,,,,,'''',,,'''''..''''''''''',,,,,;;,,,,,''',,,,,,,,,'    //
//    ;c::::::;'...';::::::::::::::;;;:::::;;;;::::;;;;;;:::::;;;;,;;;;;;;;;,,,,,,,,,,,,,'',,,,,,,,;;;;;;::::;;;;;;,,;;;,,,,''    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AKart is ERC721Creator {
    constructor() ERC721Creator("Artistken", "AKart") {}
}