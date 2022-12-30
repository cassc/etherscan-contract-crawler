// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TokenSmarts
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////
//                                                                                   //
//                                                                                   //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKOxdodxkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMNX0kddoooooodk0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWNKOxdooodooooooooodxOKNWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMNX0kddoooooodoooooooooooodxk0XWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWNKOxdooooooooooooooooooooooooooodxOKNWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWX0kddooooooooooooooooooooooooooooooooodxOKXWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMWNKOxdooooooooooooooooooooooooooooooooooooooooodk0KNMMMMMMMMMMMM    //
//    MMMMMMMMWX0kddoooooooooooooooooooooooooooooooooooooodoodooooodxOKXWMMMMMMMM    //
//    MMMMWNKOxddoooooooooooodoodxOOxdooooooooooodxOOxdoooooooooooooooddk0XWMMMMM    //
//    MMWKkxdoooooooooooooooddk0XWMMKxoooooooooooxKMMWX0kxdooooooooooooooodxOKWMM    //
//    MMNkdoooooooooooooodxOKNWMMMMMXxoooooooooooxKMMMMMWNKOxdoooooodooooooodkXMM    //
//    MMMWX0kdoooooooddk0XNMMMWNNWMMXxoooooooooooxKMMWNNWMMMWX0kddooooooodkOKNMMM    //
//    KKXWMMWXKOxddxOKXWMMWNNXK0KNMMXxoooooooooooxKMMNK0KXNNWMMWNKOxddxk0XWMMWXKK    //
//    oloxOKNMMWNXXNMMMWNXKK0000KNMMXxoooooooooooxKMMNK0000KKXNWMMMNXXNWMMNKOxolo    //
//    lllllodk0XWMMMWNXKK0000000KNMMXxoooooooooooxKMMNK0000000KKXNWMMMWX0kdollllo    //
//    llllllllodKMMWXK0000000000KNMMXxoooooooooooxKMMNK00000000000XWMMKdolllllllo    //
//    lllllllllo0MMWX00000000000KNMMXxoooooooooooxKMMNK00000000000XWMM0llllllllll    //
//    lllllllllo0MMWX000000000KXNWMMWXKKKKKKKKKKKXWMMWNNNNNNNNNNNNWMMM0llllllllll    //
//    lllllllllo0MMWX000000000KXWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMMMMMM0llllllllll    //
//    lllllllllo0MMWX0000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXXWMMM0llllllllll    //
//    lllllllllo0MMWX000000000000000000000000000000000000000000000XWMM0llllllllll    //
//    lllllllllo0MMWX000000000000000000000000000000000000000000000XWMM0llllllllll    //
//    lllllllllo0MMWXK00000000000000000000000000000000000000000000XWMM0llllllllll    //
//    lllllllllo0MMMWNNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK000000000XWMM0llllllllll    //
//    lllllllllo0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX000000000XWMM0llllllllll    //
//    lllllllllo0MMMNXXXXXXXXXXXXWMMNK00000000000KWMMWXXK000000000XWMM0llllllllll    //
//    lllllllllo0MMWX00000000000KNMMKxoooooooooooxXMMNK00000000000XWMM0llllllllll    //
//    lllllllllo0MMWXK0000000000KNMMKxoooooooooooxXMMNK0000000000KNMMM0llllllllll    //
//    lllllllllokNMMMWNXKK000000KNMMKxoooooooooooxXMMNK000000KKXNWMMMNkllllllllll    //
//    llllllllllodOKNWMMWNXXK000KNMMKxoooooooooooxXMMNK000KXXNWMMWXKOdolllllllloo    //
//    ollllllllllllodk0XWMMMWNXKKNMMKxoooooooooooxXMMNKKXNWMMMWX0kdollllllllllllo    //
//    xollllllllllllllloxOKNMMMWWMMMKxoooooooooooxXMMWWWMMMNKOxolllllllllllllllok    //
//    N0kdolllllllllllllllodk0XWMMMMNOxdooooooodx0NMMMMWX0kdolllllllllllllllodk0N    //
//    MMWNKOxolllllllllllllllloxOKWMMMNK0kxdxO0XWMMMNKOxolllllllllllllllloxOKNMMM    //
//    MMMMMMWX0kdollllllllllllllloxk0NWMMWNNNWMMWX0kdolllllllllllllllodk0XWMMMMMM    //
//    MMMMMMMMMWNKOxolllllllllllllllodk0XWMMWNKOxoolllllllllllllllodOKNWMMMMMMMMM    //
//    MMMMMMMMMMMMMWKOxdollllllllllllllloxkkxdolllllllllllllllooxOKNMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWX0kdolllllllllllllllllllllllllllllllodk0XWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMNKOxollllllllllllllllllllllllloxOKNMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWX0kdolllllllllllllllllodk0XWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWNKOxollllllllllloxOKNMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0kdolllodk0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0OkOOKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                   //
//                                                                                   //
//                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////


contract TSS is ERC721Creator {
    constructor() ERC721Creator("TokenSmarts", "TSS") {}
}