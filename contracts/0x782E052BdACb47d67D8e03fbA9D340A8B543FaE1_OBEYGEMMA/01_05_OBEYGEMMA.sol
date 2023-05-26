// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OBEY / GEMMA
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
//                                                                      ....             ..'.                                     //
//                                                                 .... ,'..        .  ...,cooc::,.                               //
//                                                          .  ........ '...       .'. ....,lO0KXX0kl'.                           //
//                                                     ....... ......           ...:dc;,...lXXXKXKkl;,''..                        //
//                                                  .......... ':cl:;;;;,,,,;;;'  ..:xO:  .oXNX0kko. ....''..                     //
//                                               .............,dkkxxxxdxxo;,:ld:.   :00:  .dNNdcdxl.      .',.                    //
//                                              ...... ....':lxxxxxxdddddoc'.;o:    cK0:  .oNk:lxx:.        .'.                   //
//                                           .,;;;,,,,,;:clddxxxxdddddkOOdoodxx;    ,k0:   oXOxxddl'.         ..                  //
//                                         .',;:ccllclodxddddxxxxl:;...'.......      :O:  .oXXklcodxl.         ..                 //
//                                       'lk0KKX0OK0kOkxddxdoc:;oOOOOl.              .o:  .o0xddccldxo:.        .                 //
//                                       ..,:o0X0kOOOOOxdl,..   ,kKXKkd;    .,;,,.   .l;  .cxx0X0d;;dxxd'       .                 //
//                                           .,xOkkO0OOxc.      .:dolxK0;    ,loooc,..;.  .lkdxkd:;lxxo,.      ..                 //
//                                             .dOk00OOd.         . .cOkl:;'. 'loollc;,.  .oX0dc:coxx:.        ..                 //
//                                     .::.     ;xO00Ok;      ,;'.  .'..''','':lllolol;.  .oXXOxdddc,.     ......                 //
//                                 ':::cl:.     .oOOOOd.      .,,'.':;.      'oc.,l:,::.   cOkloxxc.      ....'...                //
//                                 'cdl'    ..  .okOOxl.  ...    ,:cl:.      'dc. .. .:.   ;od::dxd'    ..'''','''.               //
//                               'lxOkc. .'lo'  'dOkxlc'  .cc,.  ..';:;...,;:oxc     'c.   ;dkkxOOx'   .;;'''',''''.              //
//                            .:o0Kkc,..,lxd,  .cxdlcccc.  .;lc;'.....'',cdxkkx:     ,l'   :kOO0KK0o'. .oxl,'''''''..             //
//                           .o0000kllodkxc.  ,dkdc::::c:'   'coddooooc;,;ldkkkc    .:o'  :OKXXXXKKOol;,lkkdc,'','''.             //
//                          .lKKOkkkkOOko,. .lO0xlc:;;:::c;.  ..;ccloool:,;coxkc    ,od;.o0KKK0Okkkxddl:,:xOOxc,,,,,.             //
//                          ,kOOkkOOOOOx;..'ll::;;::::,'.',..   ;ooddlldl;,,cdxc. .'cdkO0KOkkkxxxxxxddl:;,,o00kl;,,,.             //
//                         .oOkkkOOOOOkx:....   .........      ,oxxxxkkxoc:;:oxl,:dkOKNNX0OOkkkO0Okddoc;ol';dkkxo:,.              //
//                         :kOkkkkxkkkOOxl;'...',,'..:odl,..',cdxdxxxxxxxdoodkO0KNNNWWNNK0OkkkkOOkdooc;;lc';odkkxc.               //
//                       .:xkkkkkxxkkd::okOxlc:;,;;:cloooddodxxl,',cxkxkxdddxxdxO0KXXNX00Okxkkxxdocclc;:c;';ddxko.                //
//                     .;okkkkkkkxxkd,  'dxoll:,,,;;:clloooddxo'   .;ol:,...   .';ldkkkOOOxkOkdlcclolc:;,.,oxddkl                 //
//                     .ckkkkOkkkxdl,. .'colllc;,,,,;:ccloooodo:..   .             ':loddlcxxol;......',;,cxxddkd.                //
//                .'    ,xOOkxxxkkc'.';:ccllc:;'..','',',;clooooc.                  .,::ldxxl;.         .,lddddkx.                //
//                cl.   ;xkxxxddxdlloooc;''..      .       ..;oo;                    .',dKXKd.           .;:clcol.                //
//                ;:.   ,ddodddxxxxxdo:.     ....     ...'.  'lo:.                    .,cOXk:.         .coc::lclx:                //
//                   .  ,ddoodxxxddxlc;'..   ':;,'...,:::,.  'clo,              ... ...,;xXk:.      ....;;:ollldOx'               //
//    .'.              .:xko;oxxxxxo::;,,,..................;clcdo;.          ..,,'.,:cc'''..'.    .....:::odoodkd.               //
//     .ldc'.         ..cxkc.,xkkxl;;;,'',;;:::,.      .,:cllol;:dOl.         ..';coxxo,               .:okOkkxxko.               //
//      .lOOdc;,..   ...cdd:..oxxdc,;:;''.';:ccc;'....',:ccccoxkxddkkl;.......,:okKKOl.                'okOOkxxxdo;               //
//        .:clll:'......:llc::lcclc;:c:,'.'';::;'''',;;,;::cldkkkxdox00kdoooodxkk0Kkl.           .'.. .;xkkddolodoo;              //
//      .,...',::codooooxxdxxxkdc:;',:c:;,''',,'.','',;::::;;:odo:;coollol:;cl::ok0d;        ..   .;::,:ooollollllol.             //
//       ,lcc;,,':OOkkxxkkxxxk0Kkd:. ...,::;,''..'',,',:::,.....',;clcloooodxO0Ok00d'       ...    ....,ooooolllolll'             //
//       'llllll;:xkkOkxkkxxdxkkkOO:     '::::;,,''','',:,.      ......:oxxO0KK0KKkd;             .,,,.,odooodoooddo'             //
//       'llllll;;dxdxOxxxxxdddxdOk;......,:c::::,''''',,..   .        .,oxO0KXXKOkko'  ...   .    ....,oolllooddxkl.             //
//        'clllo;,loloddddddddoolloccxkdlcl;..''.....,,''.... ..        .'lOKKKK00Okxoc;cl.  ..        'ododddxxkkd'              //
//         .cllo:.................;kXW0ddd:'.......';;;;'. ... '.       .,:coxkOOOxdkk:':, .           ,dddxxxkkko.               //
//          .;dOkoc:co;.  .''..,ldxk00occ;,'.....,;;;;:;.   ''.,c.      .;:;cloddxddkd:cd,.:;';'.  .   ;xkkkkkOkc.                //
//           .oKkc...,,.  ,oxolxkOOdcc,'.',,;codol:,,'.     .'..lc'.   .::;ldodxx0kx0Ooxk:'ol,c:..,.   ,ddxkkdc.                  //
//            .,.... ,do:lk00kdldxkxc'...':dOXOl,....        ....lx:   .';ldkO00k0kd00kKKocOOlc:;cc.   c0K0kc.                    //
//                   .;oxxxdol;,,cdxxc...,cod:.              ....,ldc   ...,:lodxkxdkkdxOolxxoolol;.  .oX0c.                      //
//                  ....:c:c:'.',';dxd,..,,'.       .      .......,ok' .';:clldkkxOkxxxxxxddooll:,,.  .lK:                        //
//                   .....;;.....,.''.:xOOko;'..    ...   .,',;'...;dc...';cldxoooddoxxoxxdocc;. .:,...oKo...                     //
//                    ..;oo;.....c;   :KXXXKOxxxc  .'';;. .:;,lo;...:ooc::::lodxxdllldddc. ..    .lc...oXXk;.                     //
//                     .;:;.  .. :l.  :KXXXXKkdx:.','':::;'.'',:c'...,:lllc::;:ldxO0OOOl.        .dl. .,c;.                       //
//                               ...  :XNXXXX0OOo;,...';dOOd;..........';:c;'.':dkO000x::c;''.. .:x'                              //
//                                .   :XWNXXXXX0:  ...;dOKKXKx:.........',:cccloxkxoll::cooolccclc.                               //
//                                    ;OXNXXXXXKc.;odxkOO0KKXXXOl,...,'..''',:cllc:'...... .c:'..                                 //
//                                    ..,cxKXXXXOxkOKK0OOO00KKKKKOd:....... ...,.,l;'.';;'. .'.                                   //
//                                    .;lx0KXXXOkXNNNXK0OOOO00Oko:;........ .....';....,                                          //
//                                    ;KNXXXXXK0XWNNNXK0OOkdl:','.,'....... ....... ''                                            //
//                            .;;,,;;;oKXKXX00NWWNNNNNKOOdlc,..''';,....... ....... ''                                            //
//                          .cONNXKKKKKKKXXOxOKNNNNWNX0ko,':,..,'',;'..............                                               //
//                   ..   .o0OkKWXKXXXNNNWWKdcl0WNNXK0Ol,.....',.';;..''''.........                                               //
//         ...........,;,:xXNOk0WWWWWWWWWNXOc;oKWNXK00k;...'..',.';,..''..,,''.....                                               //
//      .;clooooooooolkNKOOXN0xONWWWWWWNNN0c;xXWNXKK0Od.......',.':,.',',.::.''.'.                                                //
//                                                                                                                                //
//    nft.obeygiant.com ••• gemma.art                                                                                             //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract OBEYGEMMA is ERC1155Creator {
    constructor() ERC1155Creator() {}
}