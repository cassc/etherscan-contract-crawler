// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: All Guts, No Glory.
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//                                 ..,;:ccccolc,.',,,::clc:,,'.                           //
//                               .,clllcoooddddooolldddodxdoool;.                         //
//                             .,:::ccccldddddddddollccccokOOkxxdc.                       //
//                           .,;;;;loloddxxdddddddodkxodk000OOOOOkd,                      //
//                        .';;;:::oOOkkkxddddoooooddkkodOXNNXKK0OOOx,                     //
//                      .,;;,;cloxKX0xdollooolcclllccoolcldOXWNX0kxkxc.                   //
//                     .;:;;clllclxxocllloddolcc:cldkOOkxdlcoOXNN0OOOkx:.                 //
//                     ,ccodddoc;ckKOxdc;:::;;,,;lox0NXKX0dcclox0X0O0OOxc.                //
//                    .:okOkxo:ldkOOko;..........,,;okdx0X0occccoKX00K0kxc.               //
//                   'cokKOkd:codo:,..              ....;lxkocllo0WNXNN0ko,.              //
//                  .clxKXkdlxOko;..                    .,:clkX0dxXMWWWN0d,..             //
//                 .:loON0l;okdlc'..                     .,':ONWKxxKMMWWNk:...            //
//                .:lcoOKd:dkocc,...                     .cocxNMWNOxKMMWWKc';;.           //
//                .'cloO0xxKKl;'.,'                      .:xxkXMWNNKKWMWWNl...            //
//                 .lookOk0NNOocc:..                    ..,,:xXMMWWMMMMWWNo.              //
//                 .oxxO0KNNN0xdxkkxdoc,..          .,llclollokKWMMMMMMMWNo.              //
//                 .lOOKNNK0Oxdlldk0KK0xl,.       'oOKXX0kxxdddxKWMMMMMMMW0l'..           //
//                  ,xOXNX0kOkxoooddxoool;.      .c0X0kxdxkOOOkO0KNMMMMMMMWKxl,           //
//                  .:xKXkoodOKkxxxdo;';;,..   .,coxdooooodk0KXXOx0NMMWWMMMNOxl.          //
//                  .coO0dlccldl::;;;,;:..'.   .;c;,:::;'',:lxkxookNMWNNWMWNxlc'          //
//                  .:okOd;,,,,clool:;;'....   .::..',;,,:c:;;;',ckXWWNWWWWXko:.          //
//                   'lkOd;... ..''.........   .;'   .''.','....'lkKNKOKXXKOxo;'          //
//                 ..':xkko,.            ....  .,..   ..       .cx0K0kooOk:'..''.         //
//                ..  'okkOd'          ...'.  .',,;.         .'o00Oxoccdl.    ..          //
//                    .ckO0x:,'.        .lOx:cdOkll:.        .cOK0xoodxl.      .          //
//                     :dkXXd,.         .:oxO0OK0l,.        .'cx0XXXNNO,        ..        //
//                     ,ox0NK:           ..cOkddo,.      ...,:cckWMMMNO;       ..'.       //
//                     .cdOKKd'.        .'dkxkO0Ko.      ...;::lKMMMMKxc..... .. ..       //
//                    .,cdxxdo:'... ..':d0XOxOOKNXko;. ...,:c::xNNWMMKl:;....             //
//                   ..':c:coc;,,,'';oOKX0OxxkkOOKXXKxc::ldxxdllollON0:';.                //
//                   .   ...''.':lc::clxOOkkxkkkk0KOxoccoxkO0x.    .kKl,'.                //
//                  ..          .cxdolloxO00OkkO00Odooox0XKX0,      'l:'.                 //
//                 .             .oxxoc:,.... ...';:coOXNNNWk.        ....                //
//                             .  ,cdOOxc;'..',;:cdk0XWWWNXXx.          ..                //
//                               .;cldO000OO0KXXNNNWWMMWNNNN0:                            //
//                             ..';:cloxxk00XWMMMMMWWWNK0KXNX0l.                          //
//                          ....',;;;;:lllxOKXNXXKOOXX0kkOKXXK0xoc;.                      //
//                         ..  .',;::;;;;:ox0KK0kxx0XKOxxO0K00Okkkkxl,.                   //
//                         .   ..;lddocccooodkOOOOOOOxddxkk00Okkkkkkkdoc;'.               //
//               ..       ..  ...'cdxxdddoooddxxxkkOxoodxxkOOOkkkO00Odooooc'. .           //
//                                                                                        //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract AGNG is ERC721Creator {
    constructor() ERC721Creator("All Guts, No Glory.", "AGNG") {}
}