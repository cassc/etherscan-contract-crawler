// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 1. Origins
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    ccccccccccllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    cccccccclcllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    cccccclcccccllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    lllllllcccclllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllok0Oxllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llcclllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllxKWNOolllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllolllllllllllllllllllllloxkdllllllllllllllllodxxollllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllokKxlllllllllllllclllloxOKNNXOxollllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllldxxolllodolllllllllllllllllllkNMMMMNklllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllldKWW0ollllllllllllllllllllllloxkKNX0Oxollllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllok00xllllllllllllllllllllllllllldxdolllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllloooolllllllllllllllllllllllll    //
//    llllllllllllllllllllllllodxkxxolllloxOO000OkkxollllloxO00OO0000000kolllllllllodxkkkxdoollllloxkkkOkolllldkOOO00OdlllloxOKXXXXK0kdollllllllllllllllllll    //
//    lllllllllllllllllllllox0XNWWWWNKkdldKWMMMMMMWWX0xollo0WMMMMMMMMMMMKdlllllok0KXNWWMMWWNK0kdlldKWMMMNkllokXWMMMWXkollokXWMMMMMMMMWNKxollllllllllllllllll    //
//    lllllllllllllllllllldKWMMMMMMMMMW0ooKWMMMMMMMMMMWKxlo0WMMMMMMMMMMWKollldOXWMMMMMMMMMMMMMWXkooKMMMMWkodKWMMMMW0dllloONMMMMMWWMMMMWNklllllllllllllllllll    //
//    llllllllllllllllllldKWMMMMWNNWMMXxldKMMMMWNNWMMMMMNxo0WMMMWXOkkkOkdlllxKWMMMMMWWNXKKXWWMWNOooKMMMMNOONMMMMWXkollllxXMMMMMN0kk0XNKxllllllllllllllllllll    //
//    lllllllllllllllllllkNMMMMWKxdxO0xoldKMMMMNOd0WMMMMM0d0MMMMWOlllllllllxXMMMMMMWXkdolloxOK0dlloKMMMMWNWMMMMW0dllllllxXMMMMMW0xolodolllllllllllllllllllll    //
//    lllllllllllllllllllxNMMMMMN0xollllldKMMMMWOxKWMMMMW0d0WMMMW0xdxxxolldKWMMMMMWKdllllllllllllldKMMMMMMMMMWXkolllllllokNWMMMMWWX0xollllllllllllllllllllll    //
//    llllllllllllllllllloONMMMMMWWKxollloKMMMMWWWWMMMMWXxo0WMMMMWWWWWNOllkNMMMMMMNxlllllllllllllldKMMMMMMMMWKdlllllllllllx0NWMMMMMMWXOdllllllllllllllllllll    //
//    lllllllllllllllllllloxKWMMMMMMWKkoloKMMMMMMMMMMWXOdlo0WMMMMMMMMMWOlo0WMMMMWWKollllllllllllllo0MMMMMMMMMXkolllllllllllldk0NWMMMMMWXkollllllllllllllllll    //
//    lllllllllllllllllllllloxOXWMMMMMWOoo0WMMMMMWNX0kdlllo0MMMMWX0OOOkoloOWMMMMMMXdllllllllllllllo0MMMMMMMMMMN0dlllllllllllllldk0NMMMMMNkllllllllllllllllll    //
//    llllllllllllllllllllllllloONMMMMMWOoOWMMMMXkdollllllo0WMMMWOllllllllxXMMMMMMW0ollllllllllllldKMMMMWNWMMMMWKxllllllllodolllllxXMMMMMKdlllllllllllllllll    //
//    lllllllllllllllllllxKKOkxkKWMMMMMW0oOWMMMW0olllllllloOWMMMWOlllllllloOWMMMMMMWXOxdodxk0KOdlldKMMMMNkONMMMMMNOollllld0NX0kddxONMMMMMKdlllllllllllllllll    //
//    llllllllllllllllloONMMMWWWWMMMMMWKdlOWMMMW0ollllllllo0WMMMWX0KKK0kllloONMMMMMMMMWNNNWWMMW0dldKMMMMNkokXWMMMMW0dllld0WMMMWWNWWMMMMMNkllllllllllllllllll    //
//    lllllllllllllllllokKNWMMMMMMMMWN0dlo0WMMMW0ollllllllo0WMMMMMMMMMW0ollllxKNWMMMMMMMMMMMMMMNOloKMMMMWOllxKWMMMMWKdllkXWMMMMMMMMMMMMNOollllllllllllllllll    //
//    lllllllllllllllllllldk0KXNNNXKOdllldKWWWWNOolllllllloOWWWWWWWWWWNklllllloxO0KNWMMMMMWWNX0xoloKMMMMWOllloONWWWWW0dlodk0XNWWWMMWWX0xolllllllllllllllllll    //
//    llllllllllllllllllllllloodddolllllloxkkkkxolllllllllldkkxxxxxxxxdollllllllllodxkOOOOkxdollllok0OO0Odllllldxkxxxdlllllloddxkkkkxollllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllokOdllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllldOOkolllllllllllldxolllllllllllllllllllllllllllllldxkOOOkdollllllx000000000Odlllllllllllllllllllllllllodxxxxdollllllllllllllllllllllllll    //
//    llllllllllllld0WWXxlllllllllllllllllllllllllllllllllllllllllloxKNWWMWMWNKOdlllo0WMMMMMMMMNxlllllllllllllllllllldk0KKKXXXXK0Odollllllllllllllllllllllll    //
//    lllllllllllllldOOxolllllllllllllllllllllllllllllllllllllllllo0NMMMMMMMMMMWXKkoo0WMMWNXXKKOolllllllllllllllllllloxk0KXNWWWWWNXK0Oxollllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllloOWMMMMNK00XWMWMMNOdKMMMWKkkkkdllllllllllllllllllllllllllodxxkOOO000Okollllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllddddollllllllllllllllxXMMMMNklllxXMMMMWKxKMMMMMWMMNkllllllllllllllldxdllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllld0NNKxolllllllllllllllxNMMMMWKkxk0NMMMMWOxKMMMWWNNNXxllllllllllllllo0XOolllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllld0XXKxlllllllllllllllloONMMMMWWWWMMMMMWXxdKMMMNOddddllllllllllllllllodollllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllcllllllllllllllllllllllododlllllllllllllllllllxKWMMMMMMMMMWKOxldKMMMNklllllllllllllllllllllllllllllllllllllllllllllllllok0kolllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllloxOXNWWWNX0kolllo0NNNXklllllllllllllllllllllllllllllllllllllllllllllllllxKNKdlllllllllll    //
//    llllllllllllllloolllllllllllllllllllllllllllllllllllllllllllllllloddxxdolllllllodddoolllllllllllllllllllllllllllllllllllllllllllllllllodxdllllllllllll    //
//    llllllllllllllkXXkllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllldkOdllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllloodddxxxddoolllllllllllodddddollllllooooooolllllllldxkkkxxollllodddxxxxxxxxxxxxxxdllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllokOxllllllllllld0NNNWWWWNNXXK0Oxolllllo0NNNNN0ollloOXXXNNN0olllldkKNWWWWWWX0dloONNWWWWWWWWWWWWWWWKdlllllllllllllllllllllllllllllllll    //
//    llllllllllllcllllldOKxllllllllllloKWMMMMMMMMMMMMMWXOdllloKWMMMMKollldKMMMMMMXdlllxXWMMMMMMMMMWXxoOWMMMMMMMMMMMMMMMMKdlllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllo0WMMMMMMMMMMMMMMMWXxlloKMMMMW0ollldKMMMMMMXxlldKWMMMMWXKNWWNOolkXNNNXNMMMMMWNNNNXOolllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllo0WMMMMN0kO0XWMMMMMMXxloKMMMMWOolllo0MMMMMMNxlldXMMMMMWKxxOOdllloodoodOWMMMMNOoddoollllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllll0WMMMMXdllloxKWMMMMMKoo0WMMMW0olllo0WMMMMMNklloOWMMMMMMWKOdllllllllllOWMMMMNxlllllllllllllok00kollllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllo0WMMMMKdllllldKMMMMMNxo0MMMMM0ollloOWMMMMMNklllokXWMMMMMMWN0dllllllllOWMMMMXxllllllllllllld0NN0dllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllco0WMMMM0olllllo0WMMMMNko0WMMMW0ollllOWMMMMMWOlllllox0XWMMMMMMN0dllllllOWMMMMKdlllllllllllllldxxdlllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllo0WMMMWOlllllldKMMMMMXxoKMMMMWKollll0WMMMMMWOllllllllox0XWMMMMW0olllllOWMMMMKolllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllo0WMMMWOlllloxKWMMMMW0ooKMMMMMNkllldKMMMMMMNxlllodollllldKMMMMMKdllllo0WMMMMKolllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllo0MMMMW0kkOKXWMMMMMWKdlo0WMMMMMN0OOKWMMMMWW0olld0NX0kdllxXMMMMMKdllllo0WMMMMKdlllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllo0MMMMMWWMMMMMMMMMNOolllxXMMMMMMMMMMMMMMMXOxlokXWMMMWNKKNMMMMMWOollllo0WMMMMKdlllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllo0MMMMMMMMMMMMMWN0xllllllx0NWMMMMMMMMMMWKxllloONWMMMMMMMMMMMMN0dllllloKMMMMMXdlllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllo0WWMMMMWWWNXK0kdllllllllloxOKNWWMWWNX0xolllllldk0XWWMMMMMWNKxolllllloKWWWWWKdlllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllldxkkOkkkkxdoolllllllllllllllldxkkkxdollllllllllllodkkOOOOkdlllllllllldkxxxxdllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllllllllldO0Oolllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllxKNKdlllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllcclllllllllllllllllllllllllllllllllodolllllllllllllllllllllllllllllllld000kollllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllldxolllllllllllllllllllllllo0WMMNklllllllcccllllllllllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllllllllllllllllllk0xlllllllllllllllllllllllokKXKkollllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllollllllllllllllllllllllllllloollllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Comic is ERC1155Creator {
    constructor() ERC1155Creator() {}
}