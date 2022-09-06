// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Botanical Dreams
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//          .'.     .....   ;OKKK0OOO000x;'..  .....       .,. .......... .;kKKKK0000OOo. ......   ';.   ;kl.                     //
//          ...     .........lO0OOOkkkO00o,.........        .....  .......:kXKK0000O00x,     ..'..':c,,:odc.                      //
//         ....   ...  . ... .l00KKK0kxkK0l,..'.''..             . ......cOK0OOOOO0XKd'           .;:',,'.                        //
//          .''''...   ....   .o0KXNWNKOk0Ol'';;::'              .......cOKOkkkO0XXOl.             .,.                            //
//         ','..'...   ...     .c0XXXXXXKkxxl;,,c:.         ..    ..''.:kKK00KXNXOdl;.          .  ''                             //
//        ...  .,''.   ...      .;xKNNXK00xdxo;;:'..  ...   ..     .'',d0KKXXXX0xddl,..          .',.                             //
//        ..   ...... .'.         'cok0KK0kocl:;;.........          .,;xKK0KOkxdxko,.':c:,..   ...;.                              //
//         ...       .'.          .;lccloddo;,,,'.........          ..;dOxddddkOkd,...,lxOOxo:,.. ,,                              //
//                  .,.            .:dddxdooc,.'......'...           .,cllxO0KOxo,....',:lxOOOko,.;.                              //
//                 .,. ..            :xkkO0Okd;.....,,....     .     ..;ldk00xoc'..',,,;cloxOO00Ox:.                              //
//                .,.                 ;xOO0KKKO:....',... ..  ...   ...;lodol:,,,,,,;:cclx0XNWWWWN0o.                             //
//               .,.                   'dOO0KKKO:....'. .....,,..  ';..;cc:cc,..,clloxxddOKNNNNNNNNN0l.                           //
//               ''                     .oOOKKKXO;. .'. .....;...  .,..;;,:ccc:,,;cdxOKKOOkkkkOKXNNXXXk;.                         //
//              .,.             .....    .ck0KKKKk;... .''....  .......',..'oxooc;ccoxxkOOOOOkkO0KXNNXXKo.                        //
//             .,.                  .      :k0KKK0d'.. .:;;,.  ....    ....c0OdkxccoooxO000000KKK00KXXXXKx'                       //
//             ,'                   .       ;k0KKKOc,. 'cll;.  ..    .. ..'kXOxOOdldkxdkKNWWNKK0XNXXKKKXXKk,                      //
//            .,. .                 ..       ;k0000o'. ,ooc.         .. .'lXXOk0KkoxOOOOOKNWWWNX0KXWNNXKKKKO;                     //
//           .,. .         .       ..         :k00KO;..,oo,          .. .cONXOOXX0xx0O0K00KNWWWWWXXXNWNXKKKKk;                    //
//           ',.         ..        ..          cOO00d,.;ol.  ..      .. .oKXXO0NXXOx0K0KXK0KNWWWWWWNXXNWXKKKKk,                   //
//          .,.         .      .   ..          .l000Oc,;lc. ....     .  .dXXKOKWNN0xOK00XXKKKXWWWWWWNXKNWXKKKKx.                  //
//          ''.        .      .    ..           .x0O0o,,::. .',,.       .xNX0OXWWN0k0KK0KNXXXKXNWWWNNXKKXNXKKK0l.                 //
//         .,.       ..  ..  .   ....            :O0Ok:.... ....    .. .,kNX00XWWN0kKXXK0XNXXXKXNNNNNXXK0XXKKKKk'                 //
//         ''...... .........   .. ..            .d0OOo'...  ...    ..,';OXK00XWWN0OXNXXKKNXXXXXXNNNNXX000XXKKK0c                 //
//        .;. ....  ........  ...  ..             ;O00Ol....   .,... .',c0KKK0NWWNOOXNNXK0XNXXXXXXXXXXX000KXXK00d.                //
//        ',...... ........  ....  ...            .d0OOk:. .   .........dKKXK0NNNXkONNNXK0KXNNNXXKXXXXKKKKKKK000k'                //
//       .;'.....  .......  .....   ..             :OOOkl. ... ..    . 'kKXX00NNN0xONNNNXKKXNXXXXK0KKKKKKXXK00OOk;                //
//       .:....    ....... ....'.   ..    ..       'kK0kd'  ...   .   .:0XXX00XNXkx0XNNXXKKXXXXXK00KKKXKKXXK0OOOkc                //
//       ,:....     ..... .......   ..    .;.  .',,:kXXOd;. ..   ...  'xKXXXOOKXOxkKNNN00XKKXXXKK00KKKKKKKK0OkkOkl.               //
//      .c:...    ... ..........    .'  .  ';,,,..'cx0XKxc'..   ......lO0XXXkk0OxxOKNNXOOK0KXXKK000KKKKKK0OOkkkkko.               //
//      .l:..  .. ':. ..........    .'.    ..';.  lOdkKXkl;.        .,xO0KXKkxxddxOKNNXkOKKXXKKK00KKKKKKXKOOOkOkko.               //
//      .o:.  ....... ..........  .. ..     . .'.'kXkxO0xl,.   ..   .oOO0KXKkkxdxkO0XWKxOXKKK0K00KKKKK0KX00OOOOkkl.               //
//      .dc.  .........''.......  ...... .  . ...;0KkdxOxdl.  ..    c000KXNKO0OxkO000Xkd0XKK000000000O0KK00OOOOkxc.               //
//      .dl........   ...'...... ... .........   cKKkddkkOO:...   .;OKKXXNNKOK0kk00KKdcxXXK0O00O0OOOkkO0000OOOkxd:                //
//      .ox'...  ..   ...''.........  .....cl.  .dX0kxxkOKKd''.  ,cx0OKNNNN0OK0kk00kdoxxk0K0OOO0OOOkkOOOO0Okkkxdo,                //
//       :x;    ..........'''.......  .'..';;...,OXOO0OOKKX0:...'lkkxkXNNNX0OK0OdoclxOOOkxOOOOOO0KK00O00OOkkxdooc.                //
//       .o;  ........................';;;;;,,,,l0KO0KK0XXXKl. .;loox0XNNNXOO00OlcdkOOOkOkdkOkOKKK0Okk0OOkxxdolo,                 //
//        ;:........'''....''......',;;:cclc:;,,oK0O0XKKXNXXx...;cox0NNNNX0kkO0OddKOk0XKkxdxkkK000OkxkOkxxdooooc.                 //
//        .,........,,,,;;,',''''',;;,:oolooddc:xK0OKXXKXNXX0;.':xO0XXXXXK0kkOOOxdkxx0XXOdodxkOkO000xdxddoooodo;                  //
//         .'...''...,;:;,;,,,'',,,;:::cllllod:cOK00KXXXXNNXKl';o0KXKKXKKK0kxOOOkl:okO00koldxxddkOOkdoooddddddl.                  //
//          ,;''',..',,c:;,,,,,;::clcc::::cccc;lO000KXXXXNNXXx,:xKK00000KKOxxO0OOd::loxkdccoddooodoooddxxddddo,                   //
//          .oo;,,,',::cc:,',,,;;:lolc:;;;;;;:;o0000KXXXKXNXXk:ckOOOOkO00OOkkOO0Odc:coooc:lllooododxxxxxdddol,                    //
//           ;kxc;;;;::;::;;;;;;;;:clol:;,,,,,,d0O00KXXXKXXXX0llkkkkxkO0OkkkO00OOdc;;:c::clllllddxxxxdxxxdol;.                    //
//            ;OOo;;:clllcc:ccc:::::clllc;,''.,dOO0KKKXXKXXXXKdoxxxxkOOOOkkOO00OOd;',;;:ldddoodkxxxxxxkxdol,.                     //
//             'x0xc:ldddolcc:cccllccoodxl,''.;xOO0KKKKXKKXXXKkddxxxkkOOkkOOOO0Okd;,;,;oxxddddxxxxxkkkxdol,.                      //
//              .lk0xoloddlclloodddoooodkd;''.;xOO00000KKKXXKX0xxkkkO00OkO0OO00Oko,,;:lolodddxkkkkkkxdol:'                        //
//                'codooododxxxxkkOkkkdllc:;'.;xOOO00000KKKXKKKkkO00KK0OO0K0O0Okkl',collloooodkkOOkdolc;.                         //
//                 ..,:lodooodddxxxxkkxdl:::;';xOOO00000KK0KKKKOO0KKKK000K00OOOkd:,ccllccloodxxxdolcc:,.                          //
//                  ..';:clllcllclodddollccc:;:dOOO000000K00K0K0O0KXK00KK00OkOkxl;::::cclooooodooll:,.                            //
//                  ...,;:cccloodoooool:ccccc;:dkOkO00000K000000kO0KKK0000Okkkxo;::::cclldkO00Okdc'. .....                        //
//                 .....'cdxxolodxxdolc::cc::;;lkkkOO000000O0000OOO0KK0K0Okkkxo:;:;::ccd0XXKOxl;.      .,.                        //
//                 .... ..'ckOxdooolllccc:::;,,cxkxkkOOOOOOkO000OO00KK00OOkkxo;;;::::lx00kdc,..      .'cl:'..                     //
//                 .... ....:dkOOkxolccccc::;,';dkxxxkkkk0KOkOO0O00000OOkOkxl;;:::cldxxoc,.        ..,:::::::;;;'..               //
//               .';:;'...  .'cdkO000Okxdlc:;,',lxxxxxxdxO0OkkO000KKKOkkkOko::oodxkkxo:.           ....'.    ..',;;;'             //
//           .,lddlc::;;,.     .,cdkkkOOOkdl:;'':dxxxxddddkkkO00KKXKK0OkkOxlld0KK0Okl'.           .    ...        .':c;.          //
//         .:kkl'.      ..       .':lllc::cc::;''cxxkkddkkkO00KKXXNXXKK00OdldO000kxl,..           ..   ..            .:l,         //
//        'x0l.          .        ...,cool::;:::,;dkO0kOXNNXKXXXXNNXKKXXKOxk00OkxdkKKOo'          .. ..'.              ,o:.       //
//       :0O,  ..               ...   ..:loolc:::cokOK00KKKXNNOooxOKNNNNX00K0O0OkONWWWXo.         ..   ..               ,dc       //
//      cKk'   .,;.        .    .'.     ..,:loolcldkO0KKXNNNNKc''',dNNNNXXXKKXXkkXWWXK0k;  ..     ..    ..              .:x;      //
//     :KO,   .::.             ....      .,okO00kdk000KXXKKK0d:....:dddOKXK00OdokKKKK0xo;......   .'     .               'xd.     //
//    'kKc   .l:              .. ..      .o000XNXOkkkOKXx:oxdll:';:cldxOKOkoccoOKK0Okdoc........ ..'     ..              .xk'     //
//    l0d.  .ll.              .. .'      .lxkO0XNXOdlcldxoooldxooooddllxkl;:dxxkxkkxdl:'......... .'.   .'.     ',.      .xk.     //
//    k0c   .xc            .;clc::,..    .;oxxxkxkdl:cdlcc;;:lolloooolcldl:ll::llll:,...';:c:::,....    .,.     .;l,    .:0o.     //
//    OO;   'kd.        .:llc:;',;:;..    .;:clllc:,',cl:,;:;;:lxOOkdolc:,;,.,lo;,:;. ..''';:;,,;::,.  ....       'ol. .'xk,      //
//    Ok;  .,oO:.     .ldc.  ..    ';'. .  ..,,,;,;ldd:'.....,cd000Oxdlc;,;;;:d0Odl:....   .,.    .',,;:cllc,.     .od''dO:       //
//    ox:.',..cd:.   'oc.   ...     ;;....   ...'ckXKx:'....,c:clooolclxxdoccdOKKOdlc;. .   '.      .,:dl,;lxx:.    .dxxkc.       //
//    ,oc.;l;..'lc'.,l;.   .;;.   .':,..      ..'oO0Oxc..,;',,.';;,'';cdl:;';dkO0K000Oxl;. .,.  ...'',,:o'...;xl.    cKk;         //
//     ,c,;okxc'':llll;..  .:xc..,;:'          'oOOkd:,;:lllol;;ccc::c'  .....cxOOO0KKKK0dc::,,'.....od::'....:k:    cKk'         //
//      ':,':do'  .colllc:;,;ldoolc,........,:ldxl:'. .'','.:lodddxoccc'.;::.  .:dO0000000Okkxoc::::col,......,kc.  .xX0,         //
//       .;,.'cc...cl,.',;::::loodxdollllooool:;'.    ....'.',;cllll::c:;,'. ... ..;::cloooool:,,'''',ll'.  ..lx:...c0Kk,         //
//        .,,..,;'.co:.    .',,'...''''......  ....    ...,,,;clclooc;,,.....:l:'.......',..   ..,'...'colcclodol,.:k0Ol.         //
//        .,. ....':dl,...,:'.    .....    ............  .....;:::::,...''..;lool;;;....';,......;l;,;'':oxOkdc'..cO00x'          //
//         ,'  ....:lo;..,o:. ..........  .............. ... ..',,'.....;,'cooddxxddo,',,;;'....,ll:::;;ldkkx:. .dKKOx,           //
//         ,,    ..:loo;..:l,.  ....... ....................,:,.'.....,;;,ckOOkkOOkxOkl:::::::;;:,.....:dl:,..,oKNKOd,            //
//         .,.     .:ol,;::cc;....    ...','''''',,;,...',;lxko:;,,,::::;cdk0KKKKKKOO00kollll:'........d0dccoOXNKOkl.             //
//         .,.      .;;;lddo:;....  ...';;;;,,,:llldl,.':cldxkkkxollc:;,:dO0O0XXXXXXK00K0koooxko:;,,;:xXKdxKXK0Oxl'               //
//          .'.      .':oodddo:.   ..';:;,,;:loxkkOOkc'';:cclloolllc:,,,lk000OKXXXXKXXKKKKOkdxO0KKKKKXKOook0kxo:.                 //
//          .'.        'ldddddol,.  '::;;;codkOOOOO0Ox:',;;;;;::;:;,',;cxOKKK00KXXXXKKKKKKKOkkxdxO0Okxdloddlc,.                   //
//           .'         .;looolc;,':llccodkkOOOO0000Oxl,',,,;,,,,'..';:oOKKXXXK00XXXKKKKKK00OOko;;;;;;;,,'....                    //
//    .       ..          .';::;,lkkxddkOOOOOkO00000Oxl;,'',,,'''...;::okKXXXXXK00XXXK00K00OOOOd'            ..                   //
//    .       ...             .'o0KOkxkO00OkkOOOOO00Oxl,..''''...',:oc;cdO0KXXXXK00KXXK00000OOkkl.           ..                   //
//    ..       ..             .l0K0kkO00OkkkkO0000OOd:'.  .'''.','.:o:',cxOO00KKKK0OO0000OOOOOkkx;           ..                   //
//    ..       .'.           .o00OOOOOOkxxkOO00OOkd:..      .,,,,'.;c,''':okOO00000OOkxkkOOkkkOkkd;        .....                  //
//    ...       '.          .o00OOOkxxxxxkkkkkkxo;.          ',,;,';:,''..':oxxkOOOOOxdooddxxddxxxxl;..    .,:,.                  //
//    ...       .,.        .oOOkkxdddddxxxddoo:..            .,';:;:;,''.. ..;codxxxkkxxdddxkOkkkkkxxxoc;'.. 'c,     .            //
//    .... .',. .,'.',,..':dkxdolloooooolc:;,.      ..       .'',cc:;'.'..    .';codddddddooodxxxkkkkkkkkkxoc:cl'. .',',,'..      //
//     ....;ldOo,cocclxxodddollllcc;,'''''............   . ...''';;:;'''......   ..,:lloooooollloodddddxxxxxxxkkkdooolllc::,'.    //
//        .;..oOooo:;cooolllc:;'..            ....''.   ......',,,,::'''...........',;::::;,,';::;;,;;::ccclloodxkkOOxlc:,..'.    //
//         .. 'oolcccccc::;'..                 '..'..  .....  ';,,,:;'''.........,:;;;;;;'....'..      ...'',''::;cldxkdc,  ..    //
//         ...,::::c:;,...                        ........    ';;,,;;','..''....'::;,,,''..',,.................;'..':;:loo;.      //
//         ..;cllc:,..                            ....,'......';;;,;:;,,''','...,;;,'''''',;,''''...       .''';:,',,..';cdo'     //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BTNY is ERC721Creator {
    constructor() ERC721Creator("Botanical Dreams", "BTNY") {}
}