// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Future editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                  .;'                                                       //
//                                                 .o0Ol,.                                                    //
//                              .lc,.           ..,xKKKKKOo:.            ..                                   //
//                              ;O0Oxc.      .'.'ck000KXKKKK0l. ..',;,.  .,.                                  //
//                              l00OddxxdlccoOK0OK0xlox0KKKKKkoldkO000x' .,.                                  //
//                              l00kc',lkKXXXXKKKKOocc:o00K00OkkO000KK0: .;.                                  //
//                              ,k0ko:;;ckKKKKK000kdllclxkOkdc;:xOkO0KKo..;.                                  //
//                              .lkOkololdO00K0dldkxoolodddo:..:dkO0KOl,..;.   ....                           //
//                .,;:clllc:;;,.':,:kkdoddO0kOxl;:odlolcclol,.,ldxO00Oxoc:olcodkOkxc.                         //
//                 .;lloddxkkkkkkxl:dkdooodl:ooc::cc:c:;:;cl;',,;d0O000KKKKKKKKKKK00Od:.                      //
//                 .;dxddooooodxkOOOOkdlcldo,,:cc::c:::;;,,:,'''ckxddxk0000KK0Okxxk00Od,.....                 //
//               ';;:ldkOOOkxxddxxxkOkdl::lc,'';:;;::::;;,,;,''.:olccoxOO000Okkkkxkkdolcccloo;                //
//             .lOOxollloddxxxxxkkdlddc:;;:;'..';;;:::::c;,;,..':lc:clxOO00OOO000OdlccoxkO0Oc.                //
//            ,xKKKK0kxdooolccccodoldo:,',;,...';,';:;:::,','..,:c:;,:dOkkOOO000xlcodkO0KK0x,                 //
//          'lxkkkkxddxkxddlc:;;:c;;ooc:,.,,...','';;;;;;,','...,;;,:lxkxxOOO0OdlloodxkOOOkxd:.               //
//        .;loodxkxdoccodxxxdl:;:c;:ol;:;,,....','',;;:;,'';,...';::cldxdxkxlc:;;,;;::ccloddddc.              //
//        ,oxO000Okxdl:;;:cllol:cl;;oo;,;;;'...';,',;;;,,,,;,..',:::cldxoll:',,,,'''',,;::cclll:.             //
//        'kKKKKK00Okdolc::;,cc,;c,'cc,,:::,...,;;;,;:;,;,';'.':cdo:;:lo;,cc;codxdl:;;;;::ccccll:.            //
//       .o0KKK000Okxdoolc:,,cc',:'.::..',,'...;:;,,;:;;;'.,;;;,';;'..:c,,clldkO00K0xlccllooolllodc.          //
//     .ckOkdoloddxxkkkkkdoc,::.,:'.::....''...',,,,;::;;'.''','.'....:c,;oddxkOO000Odlloodxxxdolodl'         //
//     .:lddocodxkO0000000Oxlcc:ldl:lc.........';,',;:;,,'.......,'.''coclxkOO00OkollddxkkkOO00kdlclo:.       //
//    .;cdkkkkkkkkOOOO000OOkxkOO0Oxdxl,...'...cxko;,,;;,,'';'...';:coxkOkOOkkOxc;,,,,;cldkOOOOO0Oo'....       //
//    oooodddddolc:;::cdxkkO000000Okkdc,'.'..cO0Od:,,;,,;:okc.......',locco:lxl'.........',:clloxx;           //
//    ;ll:;;,,;;;,,'''',;;;oO00000000Oxdlc:;';dxxxl::cldOOOd,....'....;c'':;ckl'.............',,;ll.          //
//    .:odddolc::;;;;,,,'.'o000KK00000kocc:,....,;,;codddl;,....,::collc''c:lxl'.............'''',;.          //
//    .;;;codolllcccodxdl;,ckO0xddc:oo:,,;;,....'..,;clll:;;;;:ldxkO00kl''ccldl,...........',,:c:;,,.         //
//    .::lll:,''',cdO0Oxl;',lxk:,c'.:llcc:;'....'',,;codddooodxkO00KKKOl',lldkdc,'..''',,,'',:codoc;,'        //
//    :do:'.....,okkdlc;,'.''cx:,c'.cdxdoc:;''.';,;:;:coxkkOkkOO0000K0Oo,;lldkxxxo:,,,,;;::;,;cddodoc;.       //
//    l;.      'ldddoooll:;,,lkc;l;,lkkxolooc:;:cclc:c::lldOOO000000OxxxlldookxxO0kl:;;;::ccc:;:oolcll:'.     //
//    .        .;lxkkkkxxdooldkolo::dkkkxxkkkxddddoc;c::c:clloxO0OkxolxkxxkxxkxdkO0Odolllccccc:;,;cllcc;.     //
//               .:oxkOkkkxxdxkdddookOkkkO00OOkkkxc;:c::cclolloxxoccclxOkkOOOOkxkkO0kllxxxdolc:,'..''''.      //
//            .',,',;ccllloloxkkkOOO0OOOOO0000OOxocccc::lloddodddoolooxOOO0OOOOkxxxko. .,:::;'..              //
//          .:c:,'..........,xOO00000OOOkO00OOkdlloooo::lloddddddddddddkxkOOOOOkxoll:.                        //
//         ,::,,,,,,'''''...,x00000000OkxkOkkxdoooodddlclodkxxxdxxxxxdxxlcoolxkkkdc;.                         //
//         .,:::;;;,'.......'oOO0000K0OOxdxO0Oxxkxxxxxdododkkxxxkkkxdodxl';,.cc;:,.                           //
//                     ......ckO0000K0OOOkkOkxkkkxdookxdxdxkkkkkkkxdoldd;.,'.c;...                            //
//                    .......:dx0000K0OOOOOkxxkOkxdddkkxxddkkkkkkkdollol'.,'.c;...                            //
//                  .........:c,l000K0OOO000OOOOkxkkOOkxxddxkkkkkxollccc'.,,'c;...                            //
//                 ..........;:.'x00K0OOO0000OkxxxxxkOkxkxxkkkxxddllc:::'.cl:l:',.                            //
//                 ..........,,..cx0K0OkOO0Oxolodolldxxxxdddddooodllc;;:'.:lcl:,.                             //
//                 ..........',..,:kK0Okkkx:'..,c:;,:l:,;;:codoloolc;,;;'.,..:;.                              //
//                .;;;,''... .,..,':k0OkO00xc;,;:;,,coc:::loddoloo:,,,,,'',. ,'                               //
//                 ....      .;..,''ckOkO000kdllollcodlclloddolcc:'',''''',. ;'                               //
//                           .:..,'';dkxk000Okxxxdoldxdoodddol:,',.'''.''';. ;,                               //
//                           .:..,'';oocok00000OOkxxkOkddddo:,...;,,'..''',. ,,                               //
//                           .;..,'';o:'''lkO00Okxddxkdlcc:;... .;,'..','',. ,'                               //
//                           .;..,'';l;...cooxkxdolcoxc'..''.   .'....','',. ,'                               //
//                           .;..,'';l;..;dxolddoc,.:o:...,'... ......'''',. ''                               //
//                           .;..;'';l:,'.cOOdldxxdodxl;,,;;... ......'''';. ,'                               //
//                        ...;:.;c,,:oc,'.,:lxxxxdoldxl;',,,... ......','.;,.,'                               //
//            ..''','.':;,';loc';l:;coc,'.,..':oxxddxkd:;;;,'....'....,,..,'.',''.                            //
//      ..','.;looc::,';c,'.;ol',llcloc'..'....';::cdkd:;;;;'....'...',;'.,'.,;,'...,,....                    //
//    ,'',,;;'':lol;,:,';:,'.:o:::;cdxc'..'.....''.'co:...',.....'..'';:,.;:;c,..'cdoccc,...  .               //
//    ,:''',:;.'clll;,:,.,:,.;oddl,,lxo:'.......'...:o:...',.....'..'';c:;lc,;;'cxkdlc:,........,..           //
//    ';;.',,;,.'cl:c;;c,.';,;c:oxl;loc;::c;....'...;l;...','....'.',;loc;c;.:odkdllc,........';;''...        //
//    '';'';',:;.'cc;:;,:;..':l,,ollddc'.':cclclc;'.;l;...',,',,:lcc::cc,,lllddolc:,........',,.....''...     //
//    ,,,,.';,,l:'':c,,,,,;;.,l;;c,,odl:;,,'..':cc::ldoc::clc::;::''',cdooxocll;,....    ..,,.',..,...'..     //
//    ',,,,',:,,cc,';:;'''';:cl,;l;,cc:;;:c:;,',,...,:,....,'...,::clldxococ';;....    ..,,'..,'.:;..'..      //
//    ,'''';;,;;;:lc,;:;'....:l;:l;;ll;'..,,',':c:;;:lc;;:looloooolc::lo:;lc';;..... ..''.'''...;,..'..       //
//    ,,,,'';:,;c:;c:;;;,,''';:,:l;,clc;,','....,''':oc;,;cc:;;,;;'',;ldc:o:.''.........''... .,:'''..        //
//    .'',,,,,;,;::,',;;;,,,;cl;:l,,cl;,',:;,,';:;,,clc,.',;,',;:c:;;;ll;,l:.,,,,....';c:...  .,'......       //
//    ...',',,;;:::::''',;;'':lldxc:ll:,,,:;,;;clcccoooc::clc::;::;;;;lo:;ol;;,.....;c;,'... ..'..  ....      //
//    .....',,;;;::ccc:,',;;,:;,:dooxxdc:;:;,,,:c;,;::c:;:clc::;;:;;::lo:;lc.....,;cc::;;'......      ....    //
//    ......',,,,,;;::cc:;,',cc;:l;,oddoolol:;;::,'',,;;',;::;;,;;'',,cl'.;' .'.';;,',;::,....         ...    //
//    ........',;;;;;::;::;,';:;lo:;llc;:coolc:cc:;;;,::;;:c:,,.''....;;..,' ..  ..   .,,...             .    //
//    ........'',;;;;::;,,,,';;.;c;;odl:;;::;;:clc:cc;;,..','....'....;:'.:,.,,..........                     //
//    .........',;;;:::;;,',,::,:c;;cll;,;:;''.';,',;,,,.',;,...,:;,,,:c;,:;':c:;......                       //
//    .........',;;:::;;,,,,';:,;:;;ccc,',;,...,;,',,''...';,....'....,,..'. ';,...                           //
//    ..........',;:::::;,,'';;,;:,',:;..';;;;,;:;,,,,,'.';ccc::::;,,,:;..''.,,..                             //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NikiLe is ERC721Creator {
    constructor() ERC721Creator("Future editions", "NikiLe") {}
}