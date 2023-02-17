// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Blake Wood 1/1 Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                       ..,cc:;,'''.....                                                     //
//                                    .,cokKK0OOOOOkkkxkkxol;..                                               //
//                                 .':ldk0K0OkkkkO00000KKXNXK0ko:..                                           //
//                               .:lolloxkkxxxxxkkOkkOO0000kOKKKKOdc;..                                       //
//                             .:ddooollodooodooddooddxxxxdodxxkO0XNKkl'                                      //
//                             :OOxkOOxdolloollodooolodooolldo:''':dXNOl'                                     //
//                            ,OKKXNNKOxdlddolldooooodddddddkx:.   .cXKo;.                                    //
//                           .dXNWMMWX0OkxOOxdddddddxdddxxxkkx:     .xOc,.                                    //
//                           :KWMMMMWWXKKXNX000OOOOOkdxOOOOkdl'      ,o:.                                     //
//                          .dNMMMMMMWNNWMMWWWWNXNNNKO0KKKOko'        ..                                      //
//                          ,OWWMMMMWNWMMMMMMMWWWMMWK0XNXKOo'.                                                //
//                         .cKWWWMMWNNMMMMMMMMMMMMWK0XWWNKd:;;cc:;...,;.                                      //
//                         .dNWWMMMWWWMMMMMMMMMMMWK0NWN0kdc::lxxl:. .ll.                                      //
//                        .,kNWWMMMMMMMMMMMMMMMMMXOKWKxc;:clllc,..  .;:'                                      //
//                       ..:0NWMMMMMMMMMMMMMMMMMW0kX0c.........       ..                                      //
//                       .'o0NWMMMMMMMMMMMMMMMMMXdkNx.                 .                                      //
//                      ..;dKWMMMMMMMMMMMMMMMMMM0cdXk'                                                        //
//                     ..;lkKNMMMMMMMMMMMMMMMWMWk:cOx;.          ..''...                                      //
//                    ..,:lkXWMMMMMMMMMMMMMMWWWXd;,od;.          ....  .                                      //
//                   ..';:lOXNMMMMMMWMMMMMMMWWMXd;.,lc'..          ...                                        //
//                  ...':coOKNMMMMMMWMMMMMMMWWWWO:..;c;...  ..','';,cd,   ..                                  //
//                  ...':ld0XNWMMMMMWMMMMWWWMMMW0o,.';:,'...........lX0;.                                     //
//                  ...,cdOXXNNWMMMMWWMMMWXXWMMMNOl,'',,,'.......',cKWWKxl;,''....                            //
//                  .'cxOKNNXNWWMMMWNWMMMX0KKXWWWXOo:;,'''.........dWMMNKK0kxxdoc::;'..                       //
//               .,lxKNXNWWXXNWMMMMWXXWWNKOOO0KXXXK0Oxoc:;'...   ..xWMMNK0000O0000OOOkxl'                     //
//           .,cx0NMMWNWMMWNNNWMMMMWXXNNXKOkxkO00000000Okkdlc:;;:lkNMMMWX0xk0KK0OOkkkkkOd,                    //
//         'o0NMMMMMWNWMMMWWWWMMMMMMNKXNXX0xdxkkkkkkxxkO0XWWNNXXNWMMMMMMW0xkOOOOdolc::loOk,                   //
//       .cXMMMMMMMWNWWWMMWWMMMMMMMMNKKXXNKxddxddxxkkkOXWMMMMMMMMMMMMMMMWKxddxOd';OkldxkX0c.                  //
//       lNMMMMMMMWWWMMWMMWMMMMMMMMWNXXXNN0kkxxdodxkOKWMMMMMMMMMMMMMMMMMMXxdodkkk0KxdOkkXOo;                  //
//      .oNMWWWWWWWWWWWMMMMMMMMMMMMWNNXXNNKK0xdxdxkOXWMMMMMMMMMMMMMMMMMMWN0xxk0XWNxckKOKXOdl.                 //
//      .'oKWWWWWWWWWWMMMMMMMMMMMMMNNWNNNXNNKkddxkOXWMMMMMMMMMMMMMMMMMMMWNXKKNMMMNxo0KXWKxxo,                 //
//     ...:ONWWMMMMMMMMWWWWMMMMMMMMWWMWMWWWWKkddkkOKWMMMMMMMMMMWWMMMMMMMMWWWNNNWMNkd0NWNkO0kl.                //
//     ..;xOOOKNWWWMMMMMMWWWMMMMMMMMMMMMMMMMNOoooodkXMMMMMMMMMMWWMMMMMMMMMMWWXXWMNkxKNKkOXX0x;.               //
//     ..:OKKKXNXKKXWMMMWWWMMMMMWWMMMMMMMMWWW0oc::l0WMMWWMMMMMMMMWWMMMMMWWNXX00WWKkOXXkkXNXkdko.              //
//     ..oKXWWKO0KXXXKXNXNMMMMMWWMMMMMMMMMWWWXo;,;oXMMMMMMWWMMMMMWNWMMWWNN0Okl:xK0OKNWNNWW0oxKKk,             //
//     .;kKXXNKO0NWMMNKKNWMMMMWNWMMMMMMMMMWNXXOc,:xXMMMMMMMMMMMMMNWMMMNXNNXK0o:dK0KNWMMMMXxo0NXKx;            //
//    ..c0XNWWNK0XWMMMWWMMMMMMWWWWNNNWWWWWNXXXKxccxXMMMMMMMMMMMMMMMWWNXXNWXNWNXXXXNWMMMMMNkxKNNKxl,           //
//    .'dXWNXNWMNKNWMMMMWWNWMWWWWNK0KXXXNWXXNXXKdlxXWWWWMMMMMMMMMMMWWNXKXXNWMKlxNWWMMMMMMWK0XWWKdodc.         //
//    .,xWMWKO0NWWNWMMMWWNNWMWWWWNK000OKWNXNNKXWNkxKWWNWWMMMMMMMMMWWWNXX00XWWx,xWWWMMMMMMWKKNWXxok0d;         //
//    .;OWMMN0xk0NWWMMMMWWWWWWWNNXKXKkkKNNNXKKKXWWNNMMMMMMMMMMMMMMMMNXXX0k0Nx'oNN0KWMMMMMWKKWNklkKxkd.        //
//    .c0WMMMWKxdkXWMMMMMMWNNNWNWNNN0xOXNNNXXWX0NMWWMMMMMMMMMMMWWWMMWNNXOkKO'cNMXxOWMMMMMWXNWOldX0d0O:.       //
//                                                                                                            //
//             ____    ___             __                  __      __                      __                 //
//            /\  _`\ /\_ \           /\ \                /\ \  __/\ \                    /\ \                //
//            \ \ \L\ \//\ \      __  \ \ \/'\      __    \ \ \/\ \ \ \    ___     ___    \_\ \               //
//             \ \  _ <'\ \ \   /'__`\ \ \ , <    /'__`\   \ \ \ \ \ \ \  / __`\  / __`\  /'_` \              //
//              \ \ \L\ \\_\ \_/\ \L\.\_\ \ \\`\ /\  __/    \ \ \_/ \_\ \/\ \L\ \/\ \L\ \/\ \L\ \             //
//               \ \____//\____\ \__/.\_\\ \_\ \_\ \____\    \ `\___x___/\ \____/\ \____/\ \___,_\            //
//                \/___/ \/____/\/__/\/_/ \/_/\/_/\/____/     '\/__//__/  \/___/  \/___/  \/__,_ /            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BWOA is ERC721Creator {
    constructor() ERC721Creator("Blake Wood 1/1 Art", "BWOA") {}
}