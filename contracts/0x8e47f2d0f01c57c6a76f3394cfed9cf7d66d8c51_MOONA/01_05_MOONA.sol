// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ENTRY LIQUIDITY
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//    ...                  ,c.                                                                                                                                                             //
//                                                                 ;o'                                                                                                                     //
//                                               .                 ;d;                                                                                                                     //
//                                            .                    'l;                                                                                                                     //
//                                             .         .         .c;                                                                                                                     //
//                                             ..        ..        .c;                                                                                                                     //
//                                                   ............  .c:.                                                                                                                    //
//                                                    ........     .;;.                                                                                                                    //
//                                                                  ''                                                                                                                     //
//                                                               ..,colccllllc:;'..                                                                                                        //
//                                                       ..,:loxkO0KXNNNXXXXXKK0Oxo,    ..',,'..                                                                                           //
//                                                     .cx0KNNNWWWWWWWWWWWWWNNNXKKKkc,,;cloddooo:                                                                                          //
//                                                    .cKNNWWWWWWWWWWWWWWWWWWWWWNNNX0xodxkkO0000d.                                                                                         //
//                                                    .dKNWWWWWWWWWWWWWWWWWWWWWWWWNXKOkO00KKKKK0Oc.                                                                                        //
//                                                    ;xKNWWWWWWWMMWWWWWWWWWWWWWWWWNK00KKKKKXXKKK0d,                                                                                       //
//                                                   .lkKNWWWWWWMMMMMMMMMMMMMMWWWWWNX00KKKXXXXXXXXKOl.                                                                                     //
//                                                   ;dOXNWWWWWWMWWWWMMMMMMMMMMWWMWWNK0KXXXXNNNNNNNXKkc.                                                                                   //
//                                                  'lx0XXNWWWWWWWWWWMMMMMMMMMMMWWWWNXO0XNNNNNNNWWNNNXKx;                                                                                  //
//                                                 .:xO0XXNNNWWWWWWWWWMMMMMMMMMMWWWWWN00XNNNNWWWWWWWWNNX0o'                                                                                //
//                                                 'ok0KXXXNNNNNWWWWWWWWMMMMMMMMWWWWWNX0KNNNWWWWWWWWWWWNNXOc.                                                                              //
//                                                .cxO0KKXXXXXXNNNNWWWWWWWMMMMMMWWWWWWNKKNNWWWWWNWWWWWWWWNNKk;.                                                                            //
//                                                ;xO0KKKKXXXXXXXXNNNWWWWWWWWMWWWWWWWWNKKXNNWWWWWWWWWWWWWWNNXKd,                                                                           //
//                                               'dO0KKKKKKXXXXXXXXXNNNNWWWWWWWWWWWWWWWXKKNWWWWWWWWWWWWWWWWWNNX0l.                                                                         //
//                                              .oO0KKKKKKKKKKXXXXXXXXNNNNWWWWWWWWWWWWWNKKNWWWWWWWWWWWWWWWWWWNNXKk:.                                                                       //
//                                             .ck00KKKKKKKKKKKKXXXXXXXXNNNNWWWWWWWWWWWWXXNWWWWWWWWWWWWWWWWWNNNXXKk,                                                                       //
//                                             .oO00KKKKKKKKKKKKKXXXXXXXXXNNNNNWWWWWWWWWNXKNWWWWWWWWWWWWWWNNNNXXK0d'                                                                       //
//                                             'dO000KKKKKKKKKKKKXXXXXXXXXXXNNNNWWWWWWWWWXKXWWWWWWWWWWWWNNNNXXK0Oxc.                                                                       //
//                                            .ck00KKKKKKKKKKKKKKXXXXXXXXXXXXNNNNNNWWWWWWNXXNWWWWWWWWNNNNXXKK0Okxo:.                                                                       //
//                          ..'',,,;::::cccccc:lO0KXXXXXXXXXXXXXXXXXXXXXXXXXXNNNNNNNNWWWWNXXNWWWWWNNNNNXXK0OOkxxdl;......................                                                  //
//                       .,ldxxxxxdddddoooooooloOKXXXXXNNXXXXXXXXXXXXXXNNNNNNNNNNNNNNNWWNNNKXNWWNNNNNXKK0Okkxxddoc;''''''',,,,,,,;;;:::::::;,.                                             //
//                       .,cloddxxxxxdddddoooollkKXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNWWWWWNNNNNNNNNXXK0OOkxxddddolc,,,,,;:cccccllollllloooolc,.                                             //
//                           ..':lodddddddddoollkKXXNNNNNNNNNNNNNNNNNNNWWWWWWWWWWWWWWWWWWWWWWWNNXXK0OOkxxddddoool:'. ....'''.'',,,'.........                                               //
//                                ......'',;;;:lkKXNNNNWWWWWWWNNNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWNXK00Okkxdddddooool:.                                                                        //
//                                             ;kKXNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNXK00Okkxdddddoooool:.                                                                        //
//                                             ,kXNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNXK0OOkxddddddddoooo:.                                                                        //
//                                             'kXNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNXK0OOkxdddddddddddo:.                                                                        //
//                                             'kXNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNXK0OOkxdddddddddddo:.                                                                        //
//                                             .xXNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNXK0OOkkxxxddddddddo:.                                                                        //
//                                             .xXNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNXK00OOOOOOkkkkkxxdl,..                                                                      //
//                                             .dXNWWWWWWWWWWWWWWWWWWWWWWWWWWMMMMMMMMMWWWWWWWWNXKK00OOOOOOOOOOkxdxxxdoc;'..                                                                //
//                                        ..   .dXNWWWWWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMMMMWWWWWWNXKK00OOOOOOOkxdodk0KKKKK00Okxolc;'.                                                         //
//                                    .;:c:;,..'dXNWWWWWWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMMMMWWWWWNXKK00OOOOkkdlldkKKXXXXXXXXXKKKK00kc.                                                        //
//                                  .;oddddoc:;:xKNNWWWWWWWWWWWWWWWWWWWWWWWWWMMMMMMMMMMMMWWWWWNXKK00OOkxocclk0KXXXXXXXXKKKKKKKK0x;                                                         //
//                                   .;ldxkxxxdxO0KXXXXNNNNNNWWWWWWWWWWWWWWWWWWMMMMMMMMMMWWWWWNXKK0OOxoccok0KKXXXXXXXXKK00OOOOko;.                                                         //
//                                     .:oxkkkkkkO0KKKXXXXXKKKK00KKXNNWWWWWWWWWWWWWWMMMWWMWWWWNXK0Okolclk0KKKXXXXXXKKK0kdc,'...                                                            //
//                                       .,;;:::clxO0KKXXXXXKKK0Okxxxdxk0XNNWWWWWWWWWWWWWWWWWWNX0Odoodk0KKKK000Okdocc:;'.                                                                  //
//                                               .':oxO0KKKKKKK00OOkxdolldk0KKXXNNNWWWWWWWWWWWX0koodkOOOOkkdl:,'..                                                                         //
//                                                  ..,cddxxxkkkxddoooodxxxxO00KKKKXXNNNWWWWWNKkdodolc:;,,'.                                                                               //
//                                                   ..;ldddddxxxxxdddxxkkkkOOO0KKKXXXNNNNNNNK0kd:..                                                                                       //
//                                                .;lxkO0OOOOO000000O00000000000KKKXXXXXXXXXK0Od:.                                                                                         //
//                                              .:dO0KXXXKKKKKK000000000KKKKKKKKKKKXXXXXXKKK0Okl'                                                                                          //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//     /$$$$$$$$ /$$   /$$ /$$$$$$$$ /$$$$$$$  /$$     /$$       /$$       /$$$$$$  /$$$$$$  /$$   /$$ /$$$$$$ /$$$$$$$  /$$$$$$ /$$$$$$$$ /$$     /$$                                     //
//    | $$_____/| $$$ | $$|__  $$__/| $$__  $$|  $$   /$$/      | $$      |_  $$_/ /$$__  $$| $$  | $$|_  $$_/| $$__  $$|_  $$_/|__  $$__/|  $$   /$$/                                     //
//    | $$      | $$$$| $$   | $$   | $$  \ $$ \  $$ /$$/       | $$        | $$  | $$  \ $$| $$  | $$  | $$  | $$  \ $$  | $$     | $$    \  $$ /$$/                                      //
//    | $$$$$   | $$ $$ $$   | $$   | $$$$$$$/  \  $$$$/        | $$        | $$  | $$  | $$| $$  | $$  | $$  | $$  | $$  | $$     | $$     \  $$$$/                                       //
//    | $$__/   | $$  $$$$   | $$   | $$__  $$   \  $$/         | $$        | $$  | $$  | $$| $$  | $$  | $$  | $$  | $$  | $$     | $$      \  $$/                                        //
//    | $$      | $$\  $$$   | $$   | $$  \ $$    | $$          | $$        | $$  | $$/$$ $$| $$  | $$  | $$  | $$  | $$  | $$     | $$       | $$                                         //
//    | $$$$$$$$| $$ \  $$   | $$   | $$  | $$    | $$          | $$$$$$$$ /$$$$$$|  $$$$$$/|  $$$$$$/ /$$$$$$| $$$$$$$/ /$$$$$$   | $$       | $$                                         //
//    |________/|__/  \__/   |__/   |__/  |__/    |__/          |________/|______/ \____ $$$ \______/ |______/|_______/ |______/   |__/       |__/                                         //
//                                                                                      \__/                                                                                               //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//      /$$$$$$   /$$$$$$  /$$   /$$  /$$$$$$        /$$   /$$       /$$        /$$$$$$  /$$$$$$$  /$$$$$$       /$$$$$$$   /$$$$$$  /$$       /$$$$$$$  /$$      /$$ /$$$$$$ /$$   /$$    //
//     /$$__  $$ /$$__  $$| $$$ | $$ /$$__  $$      | $$  / $$      | $$       /$$__  $$| $$__  $$|_  $$_/      | $$__  $$ /$$__  $$| $$      | $$__  $$| $$  /$ | $$|_  $$_/| $$$ | $$    //
//    | $$  \ $$| $$  \ $$| $$$$| $$| $$  \ $$      |  $$/ $$/      | $$      | $$  \ $$| $$  \ $$  | $$        | $$  \ $$| $$  \ $$| $$      | $$  \ $$| $$ /$$$| $$  | $$  | $$$$| $$    //
//    | $$  | $$| $$  | $$| $$ $$ $$| $$$$$$$$       \  $$$$/       | $$      | $$  | $$| $$$$$$$/  | $$        | $$$$$$$ | $$$$$$$$| $$      | $$  | $$| $$/$$ $$ $$  | $$  | $$ $$ $$    //
//    | $$  | $$| $$  | $$| $$  $$$$| $$__  $$        >$$  $$       | $$      | $$  | $$| $$__  $$  | $$        | $$__  $$| $$__  $$| $$      | $$  | $$| $$$$_  $$$$  | $$  | $$  $$$$    //
//    | $$  | $$| $$  | $$| $$\  $$$| $$  | $$       /$$/\  $$      | $$      | $$  | $$| $$  \ $$  | $$        | $$  \ $$| $$  | $$| $$      | $$  | $$| $$$/ \  $$$  | $$  | $$\  $$$    //
//    |  $$$$$$/|  $$$$$$/| $$ \  $$| $$  | $$      | $$  \ $$      | $$$$$$$$|  $$$$$$/| $$  | $$ /$$$$$$      | $$$$$$$/| $$  | $$| $$$$$$$$| $$$$$$$/| $$/   \  $$ /$$$$$$| $$ \  $$    //
//     \______/  \______/ |__/  \__/|__/  |__/      |__/  |__/      |________/ \______/ |__/  |__/|______/      |_______/ |__/  |__/|________/|_______/ |__/     \__/|______/|__/  \__/    //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//    .a dogma must be drowned.                                                                                                                                                            //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MOONA is ERC721Creator {
    constructor() ERC721Creator("ENTRY LIQUIDITY", "MOONA") {}
}