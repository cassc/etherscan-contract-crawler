// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LIQUID HARMONY
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMNK0O0NNK0000000000OOOkkk00K0OxkO0NWWWWWWWWWWWWWWWMMMMMMMMMMMMMM                                                                                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWX0Ok0NNXK000OOO00OOO000OO000OxxkOKWWWWWWWMMMMWMMMMMMMMMMMMMMMMM                                                                                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWK0kxOKXXK00000000000000OO00OkxxkOXWWWMMMMMMMMMMMMMMMMMMMMMMMMMM                                                                                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWX00OkOKXXKKKKK000KKK00000OOkkkOO0NWWMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                                                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWXKKOkOKXKKKKKK0KKK00000OkxkkOO0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                                                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMNKKK00KXKKKKKKKKK000000OkkOOO0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                                                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKKKKKKKKKKKKK000000000OOOOOKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                                                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKKKKKKKKKK00000000000OOOOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                                                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKK0000000000000OOOOOO0KNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                                                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXK000000OxdxxkkO0KXXNWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                                                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNX0dc:;,,;lOXXNNWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                                                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNX0OOKXKxc;;,''',collooodxO0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                                                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXOxdolodl;,,,,','......'..':oxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                                                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMNkc;;;;,..,clloolcc;. .... ..'cokNMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                                                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMNk:'...... .cdkOkkxl'   ........,dNMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                                                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWOc,'......  .',;,,'.   ........';xNMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                                                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWXk:.......   ..  ...      ..,;'cOXWMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                                                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMKo,',......      ..     ...';o0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                                                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMKxc;:'.,,...          .;:,:lkXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                                                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMXkllccccl:........:c'.'lddOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                                                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXK000xc;,:;':;,;dkd:';dONWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                                                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKkl,;c:,,,,cx00d;oKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM                                                                                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXOdloxocllxKXXkoxKWWMMMMMMMMMMMMMMMMMMMMWWWWMMMMMMMMMM                                                                                                               //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK0XNX0OKWWNNXNWWMMWWWWWWWWMMMMWWWWWWWWWWWWWMMMMMMMM                                                                                                               //
//    MMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWWWWWWWWWWNXNNXKXWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMMMMMMM                                                                                                               //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//           MADEBY                                                                                                                                                                                            //
//                                                                                                                                                                                                             //
//                    ▄▄██▀▀▀▀▀███▄ ▄███▀▀▀▀▀███▄▐█████▄ ▐███  ▄██████µ                                                                                                                                        //
//                   ╚███▄      ███████,     ,███████"███▄███ ████▄▄███▄                                                                                                                                       //
//                     `▀▀▀▀▀▀▀▀▀▀   `▀▀▀▀▀▀▀▀▀▀ ▐▀▀▀  ▀▀▀▀▀▀▀▀▀-    ▀▀▀▀                                                                                                                                      //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
//                                                                                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LHOONA is ERC721Creator {
    constructor() ERC721Creator("LIQUID HARMONY", "LHOONA") {}
}