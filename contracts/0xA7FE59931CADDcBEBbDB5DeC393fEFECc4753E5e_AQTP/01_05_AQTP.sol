// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TEXTural playGROUND
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                               //
//                                                                                                                                                               //
//                 ...                         ..               ..                                                                         .kWWk.                //
//                                              .                                                      .                                   :XMK,                 //
//        .                                                                                                                               .xWM0'                 //
//        .                                                                                                                               :XMWx.                 //
//                               .                                     ...                                ..                             .xWMK,                  //
//                               ....  .                  .            .',.                               .                             .oNMWx.                  //
//                                ....                   ...            ...                                                             '0MMNc                   //
//                                                                                                                                      '0MM0'                   //
//                                      TEXTural playGROUND                                                                             ,KMMO.                   //
//         ....                                                ....                                                                     :XMMNl                   //
//         ...                  ..                             ....                                                            .        lNMMMO.                  //
//                                          .......''.. ..                                        .. .   .                             .xWMWMNl.     .           //
//                                    ..,,'.'',,;;cdxxoddc;'.                                     .....  ...                           .xWMWWMKc.                //
//                                  ...''.',;;cc:coxkOOOOkkd:. .....                              .....                                 lXMMMMMO'          .     //
//                              ...','...':odxxxxxxkOOOOOOOOko'.  ..                              ..'..                                 .cKWMMWNk;....           //
//                 ...         .',,;;,,'':okkkkkkOOOOOOOOOOkxl.                                     ..                                   .oNMMMMWNXXKOxddoc;     //
//           ...   .''.        .,;;::;,,;oxkkkkkkkOOOOOOkkxdol;.                                                              ...    .... 'xNMMMMMMMWWWWNNNX     //
//            ..     .         .';;::;;;::lodxkkkkkkkOOOkkxoc:;.           ...             ..                                        .,,.  .o0NWMMWWWWWNXNNN     //
//                  .'''..     .'',;;;;::::::cododkOOOOkkxxl;'..            .                                            ....               ..,lxOKXNWWWNWWW     //
//    ..          .;c::;,'..   .,,,;cccc:cc::coddxkOOOOOOOxl,'.                                             ..        ..... ...          .       .',cd0NWWMM     //
//    ..          .;:::;;,,,. ..',,:clddooooddxkkkkOOOOOOxo:'..                                                      ...... ....     .  .''.          .,:oOX     //
//    ..           ,:::;,'...   .;;:clodxxxxkkkOOO00OO0Xk:'...                     ....                          ..................  ..                   .'     //
//    ;;.           ....        .;clcloxxxkkOOOOOKXXXXWMX;                         .''..                      ....',..................                           //
//    ;,.          .''.          .,;::cldxkkOOOO0XWMMMMMWo                          ....                      .......................  ..                        //
//                  ',.            ..,:coxkOOkxdxXMMMMMMWd.                           ...                    .'..      ............        ...  ...              //
//                                    .',:loool::xNMMMMWO'                             .     ..   ........             ......... ..        .,.   .               //
//                                         ..,;:,:KWXNXo.                          .'.     ...............             .......... .                              //
//                                 ..         ..,xNO,..                             ..   ...............  ...            ...........                             //
//    ..                           .'.      .'ckXWMXc                                   .,:'.........      .... ..      ....''......                             //
//    ;:;.                              .;lxOXWMMMMMX:                               ................       ..          .,''''....                               //
//    ,;;.         .                  .lKNXXXOx0WMMMM0;                          ....,'....   ......                    .....   ..                               //
//     .          .'...               .xXd::,. ;XMMMWO'                        .....,,,'............                                           .                 //
//                 ......           ..'0k'...  .OMMWO'     .                      ..................                                                             //
//                  ....           ':,cKd.     ,KMMK:...  .'..                  ..................... ..      by A Q U E O U S                                   //
//                    ..        .  ...c0c    .c0MMMO'      ..            ........... ...................                                                         //
//                                   .xNd.   :XMMMMNd'                   ..'..  ...  ...................                                                         //
//                     .             ;XWO'  .dMMMMMMMKl.           ...    ....        .................                                                  ...     //
//     .              .,,.           .:d;   .OMMMMMMMMW0:.        ...    ..''..       .....  ..........                                                          //
//                   .',,.                  oWMMMKdkNMMMNk'       ...     .....  .....  ............   ..    ...                           ...                   //
//                   ..                    ,KMMMK:  ,dXWMMKc.   .....              .   ...........'''.......                          ..                         //
//      .                                 .dWMMXc     .l0WMNl .','...          .      ............'''...                              ..                         //
//      .                    'do,......   ,0MMXc        .kWMK, .''''.        ....  .............  ......                                                         //
//                          .oWMX0OO000Oo:xWMXc       .:xKWXd'.....,'.             ....   ......                                                                 //
//               ....      .oNWKd:;lkKNWMWWMX:       'OWMWk,.'cl:....         .            ..                                           ..                       //
//                        ,ONOc.     .';lxOd,       .kMWKc. .,ll:.                       ...                                   ...      ...                      //
//                       .;d:.     ...             .oNNx'  ......         ...  ..                      ...                ...  ...  ...                          //
//                  .             ..'..           .oNXl.  ....          .,coc. ...     .,;;;;:lc,......';. .'. ..         ...   .    .                           //
//            ..    .  .....       ...           .oNXl.           .     .,,'...   .'',..:xkxxkkxolccllldo:,,;cc;.....                                            //
//      ...   ...      .',,..                    ,kKOxddl;..........        ...''.'cdo'..'lxxkOOkxddkkOkl,;:;',,',,...                                           //
//    .....    ...      .',...    ....     ..........':lol;'..',;,............,:,...cl:::,':xkxxxdddddolccod:..,;c:,'.     ..                           ..       //
//    ..    ....          ....   .....      ......''...''.'...';:c:;::::;,'',;;;;;,;cc:;c:';dxxooolcccllooddl',ooc;..      ..                          .....     //
//    ..........                  ...     ......,;,'...........',,;:ccccccccccccc:::::;,'.':ooolc::looooloOkl,'''..  ..          .... ...  ..            ..      //
//    ..........                 ..'''..........,;'...............',,,,;;:lolcll:;;,,,'''..',,,::,;loolllloc:,.   .,'..     ......','. 'c:,'.            .       //
//    ............            .  .;:;:,....................'''....,,..',,''',:lc;,,'''...'',''',,..',;od:.....  ..:c;,,,'........   ...':l:,.  ..                //
//    ..',''...... .          .....;;,..................';clc,........','....,;,'''''...'''''''',,;;::::.  .     .cddool:,',..   ..  .....       ...   .....     //
//    ..........  ...         ......... ...........',;'.:ollo:..............''',,,,;;'.';;,'',,;;;,,;,'....'.  ..;dxoooc;,'',,..';'.  ...       ....  .....      //
//    .........  .....        .....................,;,..,::::'..''..'''',,,;cccoolc::c::::::::c:;;;::;;,..''...:loollc;;:;..::;;,,;,.  .. ..........'''.  .'     //
//    ........... ..        ...   ........''........''',;;,'''',,,;;;;;:cccc::::;,;;:loc::lddddl,,;;,,::,....;odooo:,:cdo:,:llcc:::,.  ...,,...  .,,,,,..':o     //
//    '.....'.... .        ...   ........,;,'...''',:cl:'..,;;;;:lol::::ldl,';:ccclc;clllodoc;;;,,;::;,,,'',,;:llc,,lOOxlldxkdolcll:::cc;,'.   ........,lOko     //
//    ..........  ......  .........',,'..;c:,..,;clol;'....'',:coddxOOkookd;ck0x:;codxxxxkkdlol,...',,',,,,,;,,,,,:loxxolllc;,colccldkOd:....,::;'...;dk0KOd     //
//    ......       .',,...........'''.....''...,colc;';c::clccldkxO0000kkxxo:okocclk0OxxkOOo:,.    ...;cccllc:;;;lkkdoc;':oooolc:ldxoc::;;:lclocloodOXWMWN0O     //
//    ....    ....  .,::;'........,:,''''.....';cl:,:dkkxkdloodxkkO00kxolloolldO0OO0Kkooddl;.     ..;okdlooolc:,:odl;;:ccoool;.:xdc::,.'cllolcdOOxokXWXKXKkd     //
//    ...  ..',::,....',,...,;'...:oc,,,,...'',:cc::ok000OxddxkOkkkkxl:,;ldxkO00KXXKOxxo;..'.    .,okkxxoc:ccc::cccc:co::xd:;::c:,''..,cl,.;lox0kxkdkK0ko:;:     //
//        ..,;:cc:;. ..'.';:cc;..,;;........'',clccccldkkk00Okkkxddoc;',codxOOxccok0d:;.       .,ldxkko::loccllcllclddd:,;:cc;''''..;dOOl''...,::dOdooc,..''     //
//    .'. ..,cc;;;,.......:c;,..,,'............,:;;:cccldOK0xoddoc,'',;ldxxolcol;;::'.....   .,lxkOOdllox0klclcccodxkkdlcc;;clol:::cccol,...'':lclo;......ld     //
//    ......,cc,.......';,....'''...........  ..':lddoc:k0xl:cdx:.';codxdoc;:cll:,.. .';;...:oodkOOdoOKKXOl;:clclxOkxxd:lkolkx:',cl:;;,'.,;;;;::,....',''',.     //
//    ;;;,',,'''..'..',;ccc:,''.........''''.,:clcldxdolooll;'''';lodddxdloddl;.     ....,lOXNXK0KKKXNKko;.';llloolldkl.'ldo:'';ccc:'....;:;''.....,:ll:'.       //
//    :c;'.'........';:;.:xo'..........'''',:clooc;cooc:;:c;''',;:llc:cllx0x;.     ...';oOKXNX0OKNWWN0d:'':doc:;::;;cddc;:;':loooc'..';:;;'.   ..,,cdc..  ..     //
//    ';:cc:;........'::;:;...  ..,;,'','.,:loollllooc,'',,,::;,'',,,,cxOxc.......':cdk0KNX0OOKNWNKxc,..,col:;'..,,',cddoc;coool;'',cll;.....,cll;.':.   ,:;     //
//    ..,::::'..........,;,.....;clc;;;;cc:cooollddo:''';:cc:;;;;;;cxO0KOl'.':lccldk0KKKK0O0KXNXOl;,...:l;.,;:c;..''.';:oxo:;;:::cdkdc'..';::lol;..   ..'::l     //
//       .;,.......'.. ......;oolc::cllclolccccloxkdc:cllc;,,;cllox0XKdc:llloookKNXKK0O00KNNX0kl,..';,,,;clc:lo;.',,,;::oxl:coxO0Oxdoc,',:clll:.. .....,:cll     //
//    . ............   .  .';co:',;:looc::;;;:::lxxxo:,''..,cdk0KKKkl,.':oolokXNWWNK0OOKNNXOo;'.',:cc:;:ldkOOkkxxollc:cc:,,:odxOkdc:cdOkdxkOxl:'......'coodk     //
//    . .'..',....   ......;;,;::::clllc;,:lol::ol;,'...'::lOKKXX0d,.':cldx0NNXK00Ok0KKK0d:'',,;cccclooxOxdox0000kxd:',;,';dOOkl:lxKNNNXXNKx:.';::;;clccoONW     //
//    .......       .;:::;''',:ccc:ccc:';xkdoc'....''';ldxOKNNNKOxc',cddkKNNXKkxkkOxodxo;.,cdxxdoodkOkxkdl::lddxkOKKx::llokK0kdxOXNNNXK00xc..,clclodoclkXWWN     //
//    ....',..     .:dxxxolc:;:clocclodc,loll:. ..''.;dO0XWWWN0xl::lookXX0O0O0XX000Oo;'';,,okddk000OKXKklclxkOKXXNNNNxlllcdd;'lKWNK000OOc.'',oxccxxlcdKWMMN0     //
//                                                                                                                                                               //
//                                                                                                                                                               //
//                                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AQTP is ERC721Creator {
    constructor() ERC721Creator("TEXTural playGROUND", "AQTP") {}
}