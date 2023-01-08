// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NUMB
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                          //
//                                                                                                                                          //
//     :olc;,'............               .......       'clol;.            ..'',;;::::;;,'..            ..',;,                               //
//                  .;::::;;,,,,,,'''...              .......      cKWWWWNk.          ...'',,,,''.....              ....'.                  //
//                  .lkxclxxxxxddxxxodddxkkkkkkxkkkxdodxdxkkxxkkkdxKXXNNNWN0kkkkkkkkkxdxdldddxkkkkxdxkkkkkkkkkookdodkkkkd.                  //
//                   lNXodWMNKKOkXMXkdxOKWMMMMKxKMMN0ddOOXMMNNMMNOOOkxXMMWNNMMN0KWNXXNNWKkO0OKXKXMNOKWMMW0KWMNlcX0dKMMMWx.                  //
//                   .xWXKWNOkO0NXXNKxdkOOKNWM0o0MWNN0dkOXMX0NMWXOOOOkXMWNNWMMKoxXKokNMMWWKOkOO0NMMXO0KX00WMMNxdXOo0NNWO.                   //
//                    .xWMWNOxkXWNXWWWK0K00XWNkoxNNXX0kxxXNK0XWWWklxNNKKkdd0NWX0kxkxxKMN0NNKKXXNMNNKxxxkOkKWXXNNWN0OKW0,                    //
//                     .xWNX0kk0NNX0kxk0KNKONNOxxKNWNK000K0ddxo0NkldKNXKkcoKNNKddkkdo0MN0XN0OdcdKXKOdxOdco0NXXXXNNNXN0,                     //
//                      .xK0OO00KKOdllok0X0OXKkO00O0XXKK0O0Okxd00xOOOXNNKkONWN0kkK0kkOKNWKOOxccxOO0KXKOdoOXNWXXNXKNWO'                      //
//                       .o0xodlkXkdO00000OxkdxkOOdd0K0NXxxOK0x0XxldOXXK00K0dkXKXKKKKOkKNOdkxOK0kcokO0kxk0NXKK0O0WWx.                       //
//                         ckooldOxONWX0kKOxxoxxk0xdkkkK0xdo0Xkk0kdxk0XX0xxk;'xkkkdloOOk00xOOxoooxxxKN0OkdOOxOkkO0o.  .:,                   //
//                          'oOxxxlkXXX0dkkddolldkOOOkkOOxdcdkxkKXxldOKNNKkOol0kloxkkdodO000kod0NN0kkdoxxkxld0KXO:    .;.                   //
//                           .xxdkxddllcoOOdxdcloOOcdOx0Xkoodxkkxdc;lxOX0OxdO0kxxxxddoddloxxdcdkkxxd' ;xkOk;.'lx;                           //
//                            'xXNNX0xk0kkKOxdxxoxkddlcx00O000KX0xkxooxOkxddkdoKNk;,ldKKoxkdldXKxxkxc.,xOOOd;.                              //
//                             .:ckXKOOXkcxOxkK0dlcllcxKNWXOxOKkx0XKkdOXXkxKOdkxkl'dxd0N0xxkOdxo;o0Xx;cxlcdo,                               //
//                        ..     .ckxllOxo00dcodk0OxO00Kko:.;x:..lOXOx0XxoOOdxc'o:,kxdONX0XK0d..,oKKl..ldoodx;                              //
//                               .;dO;.dXxo:..dXNWN0kkx;  'oK0dlodcdXNkc..:xKO,,k:.okokKWMNOc,';:,kNOl',oOxol.                              //
//                          ,d,   .cXKldWNd,.:K0xkOkxxd. ..o0KKK0:.;k0d;. .kXkoxXk.'cl0Oc;clx0Kk' lNWXOdkNKl.                               //
//                          :0o.   'OMOcdkO0dkNxxx,.:Ol .dxxXKdOx;:oolodo;cKO';kkolclxkl:';xxxkk; ,OK0dxNWNo                                //
//                          ;0c     c00dodOk:;;cOkl,;0kckX0xOxl0KdkKkx0N0xokd'lOl,:oodo:llcdxxddo..xN0:':dk;                                //
//                          .,.    .:0MXkkO::c'lKkl,;00lc:dK0clXNddKOkO0ko:cdldkxxxoloddc;x0OOdoc.,xXk.,lol.    .                           //
//                                'oloxxxkx,',.kKkc.;0Kd, :O0OoOWOdkkOxlcdOd::lxOOkkxx0XK:,OXK0x,,xKk,;KXkx,                                //
//                                ,dOKOdlxocd;;0Ol,.;OKko.lOoOKkOKkdkOkkOOlckx:oxkkdo:oXMo ,dxOkd0Nk'.okxcdc   .:,                          //
//                                ,kNMNXklc;c;lXOlcco0WOkx0KkdkOdxxcldddk0O0XOdOXOldOxlOWo.o00xOKKk'.col, :o.  ,Kx.                         //
//                               .lo0X0kdocdKxcxOOOOkkkoo0X0ko'lOxxo';xkOXXOxoOO;:xOOdxX0dd0WKldkcddcll; .xk'   ox.                         //
//                               ;dxOko,..  ,:ckkl:dxk0xcckNKd''oool:ckOOxxO0Oo. ;dOO:lOooOKWx,cxOOolol..lOOc    .                          //
//                              .od00x;     ..dNNdlKOkNO'..dOdloxc,,dxxOOodNNd.. .:;..lx0NKKXl,ookXdd0xldk:'.                               //
//                              :Oxxl. ,dx;;lldxxolKOxNX;  ,xkdc'. .kNXXKkdkxl:. .cddkd0WWkOO',dddkxoO0XKc. ..                              //
//                              :Oxko..xX0dlddxoccx0dOWWd  :Ol'  .c00KNXo;llkkxo.'kXdcx0KOd0o.'coooo;':dxxx,.                               //
//                              oKxkx';kOd:locclcdXkcOMM0:.lKOookK0OldNNo'oxOXkxdo0o,okxxolkocdxddkk;.;OKNK:.                               //
//                             .dXxod:cO0kl::;:ldONO,lNMWOcc0WWWXkl, ,KMN00OxOkc,xK:;xkkk:'kK0OOkkkl. ;0XXx.                                //
//                             '00c..dOk00xllxKXXWWX;'kKxoooox0KOoc;..;oxOOocdl.,k0c:kOd:. ;xxxxdo:. ,clxOd.                                //
//                             ,Ok;..dOdoKKxlOWN0k0Nd.,dddld0kolox0kc.  lXOxlc'.kWk:xX0o,.;loO00xo:'dXk,cKXx:c'                             //
//                              :xo;;lO:'dkkk0WN0dxOx,':xxxxkNk:lkX0c:' ,o:,do'cOOxdxoodoo0XOxdxkKxckd'.c0WO:c'                             //
//                       .o;    .cxd;cxodK0dld0000xd0x;:dddxdd,.'cOOcxOllll,;oodlldkdxOkOXWWKdcdO0xcc::odkXkol.                             //
//                       'x;    .:dxocoOkd0XdlkOx0NOkKd;',dkkx. .;cccoxkkxoclodk:,coddkkx0NOx0xooxkddloONXkdd,                              //
//                               .ckkx;;odOOxdkxldXKkKXl.,dxk0d..,,:,;odol;oKkodc;cxxOKkddcl0NxdxOxckNOdKOod,                               //
//                           .    .okxc;ddolcloclONW0k00l:kkoodl;,:ocoxxxl:OO;'d0o:::kkxx,'ck0od0Okkddxoccl,      ..                        //
//                                 'dd:ll,,d00xldk0NWOxXKo:kO;'cl:okxdKMWOd0k::locdkddxd;.;lxdckkddoccclkd'      cO:                        //
//                                  ;kodx. ,xXNkodoxXKkKWKl;o; .';cloddxklll. 'odokOooko:lddddxddx,. .;cd;       ;;                         //
//                                  .x0okl'lxkkxlcddk0kkKxloc..cdooloOd:oko;.  oOdkklxXo:xo;cOkdOdoc;:;;,.                                  //
//                                   :d:lkdoOX0oll;ldllodOOocl0NKxdkOOo,dx,lo':0klKK:;o;.oc.',.:xddkXNxxc                                   //
//                                   'ccookxxKW0o;.;0Kl;:col::xkxkO0Oddkx:.l0odOkk0kdc:;cOOdc;;xkdONWk:d:                                   //
//                                   ,xo;ckOkxllkocKWd. .xkloc.:xO0XXOxkkdl0WOx0O0NKod0KxxOOkkkxx0NW0olx;                                   //
//                       .,.         ;X0',xxoc..cddKXo...,,,:;.:O0l,:OX0OOKXK0Oc..oX0dxxooxOxdooKNKOxod0:                                   //
//                       ..          cOxkOxoodccodll:cclo:colcldo,.;:cxxxxxdddlcl,.;od;:o:'lloOdldkkolkk;                                   //
//                                  .:lkKl.,dOOOOxocldxkdoddooc:ccoooxxxxxkkkxodkdlc:ccco:':lcclcll;:ccxd.                                  //
//                                  ,xkx:'lOOkkkdxkxxxxdocoxxxxoooolccllllloollooooooolcoollolloooc,'',::.                                  //
//                                  oWWX00XK0Okdlodoolccx0KKK0x:;:;;;;:l:;;;;::::::::::::cccccclccc;,;,,,.                                  //
//                                 .xWX0Okkxdooooollc::;codoc:;;;;,;;,:c:,;;;;;;;;,,,;:;,;;;:::;;;;,,,,,;'                                  //
//                                 .d0OOxdddoollllccc::;;;;,;;;;;,;;;,:l:,;,,;;;,;;;,;:;;;;;;;;;;;;;;;,,,'.                                 //
//                                ,kKKKOdddoooolccccc:::;;;;,,;;;;;;;,:l:,;;;;,,;;;;,;:;;;;;;;;;;;;;;;;::;;.                                //
//                        ....   ,0X0KOxdocccloclolcc:::;;;;;;;;;;;;;;:l:;;;;;;;;;;;;;,,,,,,;;;;;;;;;;::::::.                               //
//                    ...'',,,...c000Oxddl:::lollllccc::::;;;;;;;;;;;;:c:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;::::::'                               //
//                 ...',,,,,,,,'.:kOkxdddollllllllccccc::::::;;;;;;;;;:::;;;;;;:::::::::::::::::;;;;;;;;::::..                              //
//              ..',,;;;;;;;,;;,.,xkddddooooolllccc::::::::::::::::::::::::::::::::::;;;;;;;;:::::::::;;;;:;. .      ..                     //
//            ..',;;;;;;;;;;;;;,..lxddddooool:::;:::::cccccccllccccllllcllccllllllccccccc::::;;;;;:::::::cc,   .   .'cl:,'.                 //
//          ..,;;;;;;;::;;;;;;:,..;dxddddooc;;:ccclllllccccccccccccccccccccccccccccllllllllllllc:;;:::::ldo'   .   .'coddoc;'.              //
//          .;;;;;;;;;;;;;;;;::'. .dK0Oxdddl:clccccccllccccccc:c:::::::cc:::::::ccccccllllllloooo:;:::::ld:.   .    ..;coddol:'.            //
//          .,;;;;;;;;;;;;;,:c;.   ;KN0kxdddlclllllllllcc:::;;;;;;;;,',,,,;;;;;;;;;;;:::::cccclc;;;:::::::.    ..     ..,:loool;.           //
//          ..,;;;,,;,;,,'..:c,.    oKOxxxxdddoooolcllcc::;;,,,,,''..col:..,,',,,,,,;;;;;;;,;c:;;;;;:::::'     ...      ...,:cc'.           //
//           .,;,,,,,,'... .;l;',,. .dkxxdddddddolc;;;;,,'''.......'lxxxd;...........''''',,;:;;;;;:::::;.    ....  ...      ..             //
//            .,,,'...      'l:;dkc. 'oxxxddolc:;;;,',,,,,''''''..;xOkxxxo;..........'......'''',,;;:::;.    ...'...';;'..                  //
//             ....       .  cxccxx:'..colcc:;;;::;;,,,,,'''....'c0Kkkkxxxdc'.........'''...'''..'',;;,. ..,,....;:,,;;;;,'..               //
//              ..,'.   ...  .ox;ckxc.  .;clcc::;;;,,,,;;:::cclccdxcldkkdc:c;,:::;;,,'''.....''',,;,..  .'::,.....cl:;;;;;;,,..             //
//            .,:lll;........  ,;;cl,     .',,;clooddxxxxxxkkkkkdddooxkxxlllcldddooollcc:;''''''...     '::,......,cc:;;;;;;;;,'.           //
//          .;loooooc''......    ....         ,0NXXK0OOkkkkkkkkkkkkkkxxxxxxxxdddddooooollc;;,,'.        .,.     ..,:c:;;;:;;;;;,,'.         //
//        .,loddddol:''.....        ..        .dWNXK0OOkkkkkkkkkkkxxxdddddddxdddddooooollc;,,,.                  ..,:c;;;;;;;;;,,,'.        //
//        'loddddl:'.......            .       ;KNXK00Okkkkkkkkxdddddddoodooooddddoooolll:;,;,.                    .:l;;;;;;;;;;,,..        //
//        .:oooc;'.. .....                      oNNX00Okkkkkkkxddxo::lllc;;clcclddoooooll:;,,.                      co,.',,,,,,;,...        //
//         .::,..    ....                       'OWNK0OOkkkxdooolllc,,:c'.,;;;;;ccloooolc;;;'.                     .ol. ..',,,,,...         //
//                   ....                 ..     cXNK00Okkkkxddooxkxdcldc,col;:llloooool:;;,.                      ;x;     ..',..           //
//                    ...                 ...    .dNXK0Okkkkkkkxoooolc::c:,::codddoooolc;;;.                      .dl.        .             //
//                    ..                  ....    .kXK00Okkkkkkkkxdolc:;:l;,lddddoooool:;;'       ..             .dl.                       //
//                    ..                  ....     'kXK0OOkkkkkkkkkxxdddocl:;ldddooool:;;,.       ..            ,dc.                        //
//                    ..                  ...       .dKK0OOkkkkkkkkkkkkkkdlcc::lddoolc:;'.        ..          .lo,                          //
//                    ..                  ...         ;d00Okkkkkkkkkkkkxxxxlclc::clc:;'.          ..        ,co;.                           //
//                    ..                                ckkOOkkkkkkkkkkkxxxxdlccc::;'.            ..    .':lc,.                             //
//                    .                                 :Okxxxxkkkkkkkxxxxxxdol:,;::;;'..        ...',:ccc,.                                //
//                   ..                                 cNNKOxddoddxxxxxddoc:;;,,;;;:,,,,;;;,;;::::c:;'.                                    //
//                   .                                  lNNNXK0kdollllccc:::::ccccccc'     ........                                         //
//                                                      dWNNXXK0Okxddooooooolllcccccc'                                                      //
//                                        ..           .dXXKKK0OOkkxxxxxxdddddolcc:::,                                                      //
//                                       ...           'OXKK00OOkkxxxkxxxxxddddlc:::c;.                                                     //
//                                       ...           ;KNXXK00OkkkOOOOOOOkkxddolccccc.                                                     //
//                                       ...           oNXKK0OOkkO00OxlcokOOkxdocccccc'                                                     //
//                                       ...        .;cOXKK0OOkkk0Oddxl;;;ckOxdocccc:c;..          ..                                       //
//                                       ...     .:xK0kKK00OOkkkk0Oxol;',;okOxdlcccc:::,,;'..      ..                                       //
//                                       ..  .;lkKNNXK0K00OkkkkkkO000xoloO0Okxolcccc:::;;;;;;'..   ..                                       //
//                                       ':okKNWNNXXKK00OOkkkkkkkkkOO00OOOkkxdlccccc::::::;;;;;;,'...                                       //
//                                  .';lx0XNNNNXXXKK00OOkkkkkkkkkkkkkkkkkxxxdolccccc::::::;;;;;;;;;;,'...                                   //
//                                'cx0XXXXXXXXXXKKK00OOkkkkkkkkkkkkkkkkkxxxxdlcccccc:::::;;;;;;;;;;;;;;;,,..                                //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LEGE is ERC721Creator {
    constructor() ERC721Creator("NUMB", "LEGE") {}
}