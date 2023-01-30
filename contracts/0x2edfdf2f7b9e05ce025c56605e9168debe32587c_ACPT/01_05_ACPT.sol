// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Acceptance
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//    WNNNNNNNNNNNNNNNNO:..                                      .,oOKNNNNXOd:..   ...        //
//    NNXNNNNNNNNNNNNNKo'..                                       ..;coddol:,.........        //
//    XXNNNNNNNNNNNNNXd,..      ....'.....       Acceptance             ............''....    //
//    NNNNNNNNNNNNNNKx;..    ..,cloddooool:'.                             ............        //
//    NNNNNNNNNNNNNKd,..   ..;odol3DNINJAHxdl:,..      ..........''..      ..........         //
//    NNNNNNNNNNNKkc'..   ..lkd:;,;:cokkdc:coxxd:.  ..,,,'.........,;,.     .........         //
//    WWWNNNNNX0xc,...   ..ckx:,,,;:lodkkxl:;cldxc..,;'..............:l;.                     //
//    WWWNNXKOdc'...     .,xOo:;,;:cdxOOOOxo:;;;cl:,'.................:d:.                    //
//    KK0Oxl:,'..        .;kkl:;,,;:ldOKK0kdc;,,,,'......3DNINJAH.....,od'                    //
//    ::;,....           .cxo:,'.',';lxOKKOdl:::;,'...................;ox;.                   //
//    ....              .'ll;,'...,''codO0kdddxxxdl;''.............',;lkk;.                   //
//                      'cc,'......'':ooooxxxxxkOxol:''.....'..',,,:llokkc..                  //
//                   ..,cc,'.........;c:;:oxdoooc',::,,,,,,,;;;,,;:::clodkl.                  //
//              .....,lxo;'..........',;,;oxxdddo:::cc3DNINJAHcldl,';loodo'.                  //
//           ...,cldkKX0l;,'.'.....'',;;;:dO0kdoc;:clllllooolox0KOo,..,coxkc.                 //
//         ..,cxKXNNNNX0ko:,',;,'''',;:cldOKk:... .:loddxxxdodOXKkc,..':odkl.                 //
//       ..,lkKNNXK3DNINJAH:;;col;;,;:cldOXx'..    'ldxkOOOOO0Odl:,'..':odl,.                 //
//     ..'lkKNXXKOkkkkxdl;,,;:dOOxl:::cld0Kl.      .,okOKK0KXXOl;,,',;;cdxo;.                 //
//    ..:x0XXXK0OO0K0Okxdl:;;;lkOOxl:::ldk0o.        .:oxkOK0kdllllol:,'',cooc;.              //
//    ,d0K0KXKOdoxxxdoodxxxoc::lxOOdlcclokOo.      ..',;:lodol:okkkxl,.....',:llc'.           //
//    xXXOkOOkocloolllllodxxoc;:lxkkxolloxOo.   .':cc:,'';:::'..cdoc,.........';lol,.         //
//    XXOdlllc::::clc:::::ccc:;;;:ok0kdoodkd,..,:ldxkdc,',;;.   .,'......    ...':lo:.        //
//    0Odc:;;;;;:::ccc:::clodool:;;lx00kxdxdc;;;:lxkxo:,,;;.   ...........     ...,cdl        //
//    ddl;;,,,,,;::cccc:clxOKKK0kdc:clx00kdl:;;;:llc:;,,;,.3DNINJAH..........':l              //
//    xdc;,,,;::::cccclllodxOO00Oxlc:::lxdlcldxxkdc;,',;.. .........................';        //
//    Oxl:;;;:::::ccccllodddxkO00Okol:;;:lok0KK0ko:;;;,..'''.........................'        //
//    0koc::::::cclloolooxxxxxxO00Oxdollox0XK0kxoccl:'',::,...........................        //
//    kxdlc:::clodxxxxd3DNINJAHOO0OkkxxxkOkxdodxkd;';cc:,'...........................         //
//    00kocccloddkO0000OxdxkO0KXXKKK0OOO00OkkOO000dcclc:;,'..''',.....................        //
//    0OxolllloxkOK3DNINJAHxk0KXWWWWXkdxkO0KK0kxxdooolc:;,'',;:col;....................       //
//    kkxolcllodk0KXNXK0Okk0KNWWWWWNx;'''cxxdollcccc::;,;;:lodddo;,'..................        //
//    Okxoc::cloxk0KK0OkkkOKXWWWWWWNOc'...,lollcccc:::cloddxxddol:;,'.................        //
//    kxoc:::cldkOkkxdoodxO0XWMMWWWN0l'....'coooooooodxxxxxxxxxxxdlc;,'...............        //
//    xolc::::oOK0kdoooodxkOXNWMWWNN0o;'....':ldOOkkxxdddxxxk0KK00Oxoc;,'.............        //
//    koc:;;;:o0XKOkxdolodk0XNWMWWNNKOkxxkkkxdox0KOxddddxkO00XWWWNNXK0xl:,'...........        //
//    ko:;,,,:3DNINJAHdk0KXWMMWWNNNNNNNNWWWWWNNNX0kkk0KXX3DNINJAHWXkl;'.3DNINJAH...           //
//    xl:;,,;;cxKX0xoloxkOOKNWMMWNNNNNWWWWWWWWWWWWWNNNNNNNWWWWNNNNNNWWXOo:,'..........        //
//    0dc;;,,;:okkolloxkkOO0NWWWWWWWWWNNNWWWWWWWWWNNNNNNNNNWWNNNNNNNNNNKxc;'..........        //
//    Xkl;;,,,,:c:::coxkO00KXNN0kO0KXXNNNNNNNNNN3DNINJAHkkk00KXNNNNNNXKko:,..........         //
//    XOl:;,,,,,,,;::lxk0000XNNx;,;cldxxkkOOOkkkxolc:;;,,'',;cldkO0KKXXKOdc;'.........        //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract ACPT is ERC721Creator {
    constructor() ERC721Creator("Acceptance", "ACPT") {}
}