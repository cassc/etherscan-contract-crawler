// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: THE ART HEIST COLLECTION
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//     .----------------.  .----------------.  .----------------.                                                                 //
//    | .--------------. || .--------------. || .--------------. |                                                                //
//    | |  _________   | || |  ____  ____  | || |  _________   | |                                                                //
//    | | |  _   _  |  | || | |_   ||   _| | || | |_   ___  |  | |                                                                //
//    | | |_/ | | \_|  | || |   | |__| |   | || |   | |_  \_|  | |                                                                //
//    | |     | |      | || |   |  __  |   | || |   |  _|  _   | |                                                                //
//    | |    _| |_     | || |  _| |  | |_  | || |  _| |___/ |  | |                                                                //
//    | |   |_____|    | || | |____||____| | || | |_________|  | |                                                                //
//    | |              | || |              | || |              | |                                                                //
//    | '--------------' || '--------------' || '--------------' |                                                                //
//     '----------------'  '----------------'  '----------------'                                                                 //
//    .----------------.  .----------------.  .----------------.                                                                  //
//    | .--------------. || .--------------. || .--------------. |                                                                //
//    | |      __      | || |  _______     | || |  _________   | |                                                                //
//    | |     /  \     | || | |_   __ \    | || | |  _   _  |  | |                                                                //
//    | |    / /\ \    | || |   | |__) |   | || | |_/ | | \_|  | |                                                                //
//    | |   / ____ \   | || |   |  __ /    | || |     | |      | |                                                                //
//    | | _/ /    \ \_ | || |  _| |  \ \_  | || |    _| |_     | |                                                                //
//    | ||____|  |____|| || | |____| |___| | || |   |_____|    | |                                                                //
//    | |              | || |              | || |              | |                                                                //
//    | '--------------' || '--------------' || '--------------' |                                                                //
//     '----------------'  '----------------'  '----------------'                                                                 //
//     .----------------.  .----------------.  .----------------.  .----------------.  .----------------.                         //
//    | .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |                        //
//    | |  ____  ____  | || |  _________   | || |     _____    | || |    _______   | || |  _________   | |                        //
//    | | |_   ||   _| | || | |_   ___  |  | || |    |_   _|   | || |   /  ___  |  | || | |  _   _  |  | |                        //
//    | |   | |__| |   | || |   | |_  \_|  | || |      | |     | || |  |  (__ \_|  | || | |_/ | | \_|  | |                        //
//    | |   |  __  |   | || |   |  _|  _   | || |      | |     | || |   '.___`-.   | || |     | |      | |                        //
//    | |  _| |  | |_  | || |  _| |___/ |  | || |     _| |_    | || |  |`\____) |  | || |    _| |_     | |                        //
//    | | |____||____| | || | |_________|  | || |    |_____|   | || |  |_______.'  | || |   |_____|    | |                        //
//    | |              | || |              | || |              | || |              | || |              | |                        //
//    | '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |                        //
//     '----------------'  '----------------'  '----------------'  '----------------'  '----------------'                         //
//                                                                                                                                //
//                                                                    .dK0OOO0KXXXKOxl:,.                                         //
//                                                                    c0Okxk0000KKKXXXKXOdoc,.                                    //
//                                                                   ;kkxkOO00OkkxxkOOO0KXNNXOdc'.                                //
//                                                                 .:kxxkOkkO0OxkkkOOOOkO0KKKKXXKk:.                              //
//                                                                 'dxdxOOkO00Ok0KKXXKKNNNXKKKKKKXKk:.                            //
//                                                               ..:xkkOOOkOOOOO000KOOKXKKK00NNNXK00Kk,                           //
//                                    .                          'lx0OkOOO00OOOkO0kkO00OOO00OKXNX0KXKK0o.                         //
//                             ,cll:lxxxl'.                      l00OkOO0OO00OkxkOOkkkOOkkkkkO0KK0KKXNNNO;                        //
//                          .,o00Odd0XXXKOddo:.                 'x0kkO0000O00OOO00kkkkkOOOkxdkO0OO00KXXXNXd.                      //
//                        .:dOOxdookKXNXXXXKOkxl;.             .lkxxO000000K00O0K0xlodxxxO0Oxdxxkkk0KKK0KXXk'                     //
//                      'cddooddxk0KXXXXXXK0kxkxxxl;.          ,k0000KK00KKKK000OxodkOkddkO0Okxdollok00O00KXo.                    //
//                    .ldxxxkOO0KKKKKKKKKKK0000OkkkOklcc;...  .o0KKKXXKKKKKKKKK0xoxOOxllodxkOOxxdooodkOOOO0KKo.                   //
//                  .:k000000000KKKKKKKKKKKKK0000OOkOO0K0OOOdld0XXXXXXXXXXXXK0K0ddxxdc:odooodxxoooodkxxkkdxOKXo.                  //
//                 'x0000000KK0OkkkkxxkkkOOOOO000000OO00000KKKKKKXXXNNXXXXNX00KOooddl;:oooolclodoccloxdodoclkKK:                  //
//               .lO00K00OkkOOO000000000KKKK000OOOOOOOO0KKXXKKXKKXXXXXXXXKKKKKKklldoc;clllll::;:llc::lddoo:,:d0d.                 //
//              .d000KKK0000KXXKKKKK00OOOkkkkkkkkkkkkOOO0XNXXXNNXXXXXXNXKKKK0kxoccllc;cccccccc:;',:lllcodoo:',x0;                 //
//             .d0000KKKKKK0000000000OOOO0000OOOOOkkOOO0000XXKXKKXXXXXXKXKK0xol:;ccc:;ccclc::::;:,,;;:lloxxdl:oOo.                //
//            .lkOO0KXKKK0000KKXXXXXXKKK00000KKKK000OOOOOkxkkkOO0KKXXXXXXXXOdol:,';:;;cllcc:;,;,';loooodddxkOdlo:.                //
//           .c00KKXXXXXXKKK0000OkkkkxxxxkkkkkkOOOOOO00OOkxodxxk0KK00KKKXXKOo:;,,'''''',:::;;,',;;;,'';ccoxkkOd:l'                //
//           .xK0OO00KKKK00OkOOkddxkOOOOOOO00000000000OOOxdooxkkO0OO0OO0KKXO:';;;;::;;,'...'',,,;,'.',;:coxkk00oko.               //
//           ;xk00OOO00OOOOxdxdxxkkkxddodxkOO0KKKK000OkkxdoolodxkkOOOO0KKXKd,,,;;;:::;::,.''.......';:ccclclkXXOOx'               //
//           cOkkOOkkkkkOOxdlclll:;,,'.'',,;::codkOOOkkxddodocoxkOOOOKKXX0d:;;;:::;;,;;,',::;,,,...;codxxo:ckkOxoo'               //
//          .oklcclododxO0Oko:;,'...........'''',;:loodddddddlokOOkkO0KXOoccccccc:;;,,,'.';:;,,..;okOxoloooocckl..                //
//          .lc.....';:cldxxxo:'.........':::;'......',;:cllolodkkxk0KK0dloollllol::,;:,..;:,...cxko;....';cdxxc'.                //
//          'c;,...  ..;ooodoolc,.....  .,'';:::,..........',;:lxOOOOOOkdoooooodxol::lc,,:c,...cxxc.......':oxxo;.                //
//          ....','... ;0XK0kdlc::;,....'.,oddxdoc;..  .....',;:lk00Oxxdoooooodkxoccl:,;c:'. .:dl:'...';;'';lddl'                 //
//           .....;lc'.dXNNKOkdllodolloollolllcllllll:,'..,:llcldkkkxxxxdlllooodddxxolc:,.. .,lc,.. .clooc;:oooo;                 //
//             ...:llokXXXX0OOkxxxxxxxxdxxdddoolloolllodxkkOOkxxkkxkkkOxlllloodkOOkxdolc,''';c:,....clloolcloc:c;.                //
//               .clok0KKK0kkkxxkkkkkkkkxdooollloodddxO000KKK0kkOOkOOOkdllllodkOkkkdolc:,;lllc;.   .';cllc;od:;,.                 //
//               .:lok00K0OkxdddxkOOOOOOOOxdooooddxkO0KKKXXKK0kkkkxkOOkoollooxOkxdoc::;,':odkOl..   'lool:,ll,...                 //
//               ,ccd0XXXK0OkxxxxkOOO000000OxdodxO0000KKKK00OOkxxxkkkkxoollooxkxdddoc;,,;cldOOd;....:xxdc,;l;...                  //
//              .xOx0XXNXXK0OOOOO0OOO00000KKK00000OOOOOOOOkkkxdodxkkOOdoolodxkkkkxoccc::cccodl;'';:lxkxl;,cldc                    //
//              cKXKXXXXXKOkkxxxkkkkO00000000K00OOOkkkkxxxxxdollclodxxolllodkkkkxoc::;,,:cloc'.:dkkkOkl,,cc:xd.                   //
//             .dXKNNNNXK0kkxxxddxxxxxxO0KKKK00K00OOkxxddddoolc::loooolcllodkOOkxoc;,'';cldxdlokxol:::;:cc:cdx'                   //
//             .oKXNNNNK0OkkOOOOOO000OkxxOO000000000Okkxdoolccc::clc:::clooxkOOkxoc:c::clodkOOOkxxddolc:cooloOc                   //
//             .lKXXXXKOOOOO000000OOkkxoldxOOO000000Okkxddolcllc:cllodxdodxO000Okdodddoooodk0000Okkxo;.':loolOd.                  //
//             .d0OOOOkxxxdddddooollc:;,ldodxkkOOOOOOkkxxdddoodoldxk0KKOkOOO000Okxdxkddooolcoxxddolc;...,:ccoOx.                  //
//             .;llllllc:;'.......''''.'d0dloodxxxkkkkkxxxddddxdodxk000OO0O0K0Okdddxxdooolc:,',,,,'.,l:..,:::oo.                  //
//              .:;''......       ....'o0K0kdllloodxxxxxxxdddxxddxOOO0000000Oxdoooooooocc::c:'.  ..;xOko,...'oc.                  //
//              .okdod:.     ..'',;:cdOKKKKKKOxddoooddddddddxxdddk0O00O00O0Okxxxoldxol:;;',cc:'. .:xOOOOko,.,l,                   //
//              .cxOKk'     'lxO0O0KKKKXKKXXXXXK0OxdddoooooodddddxOO0KOkkOOkxdddooxdoolc:;:ll:;,';xOOOOO00Oc;;.                   //
//               ,kXK:     .lxkO000K00OOO00KKXXXKK0OkddoooodxxkOxk0000kxdxxxxddddddoolcc:::ccc:cox0K00KKK000o.                    //
//    .          'kXd... .':lc:clllllcccllodxkkO00OOOkxdoooxkOOkx0XKKOkdxOOkxdddolccccc:,,;:c:;cdkKK0KKKKK0KO;                    //
//    ..         ;kx:... .',,;,'''.........',codxdddxkkkxxkkOOxxOKXK00OOK0xoolcllllc:;,''';::;:dk0KKKKKXXKK0Kk,                   //
//    ...        ,dl,...'coodkOOkkxxdollc:,...';coxkkkOkOkkOOxxkkO0OOOkOkooxxoc:cc:::cc:::::;;lk0KXXKKXXKKKK0Xx.                  //
//    ...        .col:'.cdddddddddxxxxxkO00kdlcllldxxxxxkxk0Oxdxxxxkkxddddkxoooooll::cllllc;,ck0KXXKKKKKK0KK0KXl                  //
//    ...         .:odoodxdddodxkOOO00000OOO000kxxxdooddxkkxxdxxkkxxxxxkxdoooolccc:;::cc:;,':xk0KKKKKKKXXKKKKKNO'                 //
//    ...         .'lxxxkOOOOkxxkkkkkkkkkkkkkOOOkkkkxdooddddxxkkxxxdxxdoooooc;;:;,''',;,''.,oxO0K000KKKKKXKXXXNNk'                //
//    ....         .,oOxlllllooodddddddxxkkO000OkkOkkxdoddkkxdxkxxkxololllllcclc,,,',::,..'cxO0KK00000KKKKKKXXNNWO'               //
//    .......       .cOOxdxkO000OkkkkkxxxkOO0000Okkkkxddxkkxxddddxkkkxkxl:::cc:,';:;,,''';okO00KKK000KKKKKKKXXNWWO.               //
//    .......       .lKKXK0KKKKKKKKXXKKK00KKK0000OOkxdxkkkxxdoooodxkkdlc:;;,,,,,::;'''..:dk0000000000000KKKXXXNWO;                //
//    ........      .xXKXKKKKK0000KKKK000KKKKKKKKK00xdkkxdxdoddoodxxd:;::;:c:;,;;.....'lkO00000000K00000KKKKXNKo;'.               //
//    ..........    ,OX0KK0000000000KKKKKK0KKKKK0Okdodxxxxddddllodxo:;;;:cc:,.......'cxO00KKK00Okdolc:clodxkOx;...                //
//    ..........    :0XK0OOOO000000KKKKK0000KKK0Okdooxxoccllclll:;;,''',;;''.......:dO00KKKK0kdc,...........'....                 //
//    .......... . .:OKK0OkkkOOOOO0KKKK0OO0OO0Oxkkdodd:,;:::::,'..'....',........;oO0KKKKK0xl,...................                 //
//    ...........   'dOO00OxxxxxxkOOkOOkkkOOkxdxkdoll,'::,'''..................,oO000KKK0kl'.......  ...........                  //
//    ........... . .:dxOOOkdooodxkxxxolodxxdxdocc;'...''....................'lk0000KK0xo;......    ...........                   //
//    ...........    .':dkkxdlcloooolccccclolc;,,'.........................,cx00000d::;...     ...............                    //
//    ............    ...;loo:'......,:;,'...............................,okOOO00Ol........ ...............                       //
//    ..........          ......  ..';:;'... .........................,:okOOOO00O:........................                        //
//    ...........                   .....   ........................'ckOOOOOO0000x,....................                           //
//    ...........                             ...................,::oOOOOOOO00000koc'..............                               //
//    ...........                              ................'lkkOOOOOOOO00000Okxl,..........                                   //
//    .........                                ...............'okOOOOOOOO00000000Ol'........                                      //
//    ...............                          ..............;dOOO00OOOO000000000x,.......                                        //
//    ...............                          .............,dOO0000OOO000KKKKK0d;.......                                         //
//    ...............                           ...........,oO000000000KKKKKK0x;.                                                 //
//    ..............                             .........'lO000000000KKKK0Od:.                                                   //
//    ..............                              .......':k00000OO00000xl:'.                                                     //
//    ..............                              ......'cxO000OOOOO0Od;..                                                        //
//    ..............                               ....,cxOOOOOOOOkko:.                                                           //
//    ..............                                ..'cxkkkkkkxoc:;.                                                             //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TAHC is ERC1155Creator {
    constructor() ERC1155Creator("THE ART HEIST COLLECTION", "TAHC") {}
}