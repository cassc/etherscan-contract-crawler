// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Art For Fun
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOxkXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkoldKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0dlllxXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0olllldKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKdllllloOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXxllllllldKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKollllllllxXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOolllllllllxKWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOllllllllllldk0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOllllllllllllloxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOollllllllllllllokXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKollllllllllllllllokKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXxlllllllllllllllllloxKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMW0olllllllllllllllllllox0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKOKWMMMNklllllllllllllllllllllldOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0dlxXMMMMXxlllllllllllllllllllllllokKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMXxlllxKWMMWKxllllllllllllllllllllllllokKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWOollllokKWMWXxlllllllllllllllllllllllllokXWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMNklllllllox0NWXkollllllllllllllllllllllllld0NMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWklllllllllodOXXkollllllllllllllllllllllllloxXWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMW0ollllllllllldOKxllllllllllllllllllllllllllld0WMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMXxlllllllllllloxdollllllllllllllllllllllllllloONMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOolllllllllllloollllllllllllllllllllllllllllloOWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWXXWMMMMMMMXxlloollooooollooooooooooooollllllllllllllllllo0WMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMXxdKWMMMMMMWKdloooooooooooooooooooooooooooooooooooollllllldKWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMNOoldKWMMMMMMNOoooooooooooooooooooooooooooooooooooooooooooookNMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWNOdoookNMMMMMMWXxooooooooooooooooooooooooooooooooooooooooooood0WMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWKkoooood0WMMMMMMW0dooooooooooooooooooooooooooooooooooooooooooookNMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWXkdoooooooOWMMMMMMMXkooooooooooooooooooooooooooooooooooooooooooooxXMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMWXOdoooooooooONMMMMMMMNOoooooooooooooooooooooooooooooooooooooooooooodKWMMMMWWMMMMMMMMMMMM    //
//    MMMMMMMMMWXOdoooooooooookNMMMMMMMNOooooooooooooooooooooooooooooooooooooooooooood0WMMMMXOXWMMMMMMMMMM    //
//    MMMMMMMMN0xoooooooooooookNMMMMMMMXkooooooooooooooooooooooooooooooooooooooooooood0WMMMW0dxKWMMMMMMMMM    //
//    MMMMMMWXkooooooooooooodoxKWMMMMWNOdoodddddddddddddddddddddddddoooooooooooooooood0WMMMWOood0WMMMMMMMM    //
//    MMMMMWXxoooooooooooodddddONMMMWKkdoddddddddddddddddddddddddddddddddddddooooooood0WMMMXxooodOXWMMMMMM    //
//    MMMMWKxoooooooooooodddddddOXNKkddddddddddddddddddddddddddddddddddddddddddooooooxKMMMW0doooooxKWMMMMM    //
//    MMMWXxoooooooooooooddddddddxxdddddddddddddddddddddddddddddddddddddddddddddddddokXMMWKxooooooox0WMMMM    //
//    MMMXkoooooooooooooodddddddddddddddddddddddddddddxO0Oxddddddddddddddddddddddddod0WMWXkoooooooood0WMMM    //
//    MMNOdoooooooooddddddddddddddddddddddddddddddddddkXWNKkddddddddddddddddddddddddkXWWKkdooooooooooxKWMM    //
//    MWKxooooooodddddddddddddddddddddddddddddddddddddkXMMWNOxdddddddddddddddddddddxKWN0xddddoooooooookXMM    //
//    MWOdooooooddddddddddddddddddddddddddddddddddddddkXMMMMWKkdddddddddddddddddddx0XKkddddddddodoooood0WM    //
//    MXkoooodddddddddddddddddddddddddddddddddddddxxxxONMMMMMWKkddddddddddddddddddxkkdddddddddddoooooookNM    //
//    MKxooddddddddddddddddddddddddddddddxxxxxxxxxxxxxKWMMMMMMWXkxxdxxdddddddddddddddddddddddddddddooooxXM    //
//    WKdodddddddddddddddddddddddddddxxxxxxxxxxxxxxxx0NMMMMMMMMWKkxxxxxxxddddddddddddddddddddddddddddooxXM    //
//    WKddddddddddddddddddddddddddxxxxxxxxxxxxxxxxxk0NMMMMMMMMMMW0xxxxxxxxxxxxdddxxxxxddddddddddddddddoxKM    //
//    MKxdddddddddddddddddddddxxxxxxxxxxxxxxxxxxxxOXWMMMMMMMMMMMMXOxxxxxxxxxxxxxxxxxxxxdddddddddddddddoxXM    //
//    MXxdddddddddddddddddddxxxxxxxxxxxxxxxxxxxkOKNMMMMMMMMMMMMMMW0xxxxxxxxxxxxxxxxxxxdddddddddddddddddkNM    //
//    MNkdddddddddddddddddxxxxxxxxxxxxxxxxxxxk0XWMMMMMMMMMMMMMMMMWXkxxxxxxxxxxxxxxxxxxdddddddddddddddddONM    //
//    MW0ddddddddddddddddxxxxxxxxxxxxxxxxxkOKNWMMMMMMMMMMMMMMMMMMMNOxxxxxxxxxxxxxxxxxxxdddddddddddddddxKWM    //
//    MMXkddddddddddddxxxxxxxxxxxxxxxxxxk0XWMMMMMMMMMMMMMMMMMMMMMMNOxxxxxxxxxxxxxxxxxxxxxxddddddddddddkNMM    //
//    MMW0xddddddddddxxxxxxxxxxxxxxxxkOKNWMMMMMMMMMMMMMMMMMMMMMMMMNOxkkkkkkkkxxxxxxxxxxxxxxddddddddddxKWMM    //
//    MMMNOddddddddxxxxxxxxxxxxxxxxxOKNMMMMMMMMMMMMMMMMMMMMMMMMMMMXOkkkkkOKXOxxxxxxxxxxxxxxxdddddddddONMMM    //
//    MMMWXkddddddxxxxxxxxxxxxxxxxk0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkkkkkkKWWNOxxxxxxxxxxxxxxxdddddddkNMMMM    //
//    MMMMWXkddddxxxxxxxxxxxxxxxxkKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOkkkkk0NMMMXOxxxxxxxxxxxxxxxdddddkXMMMMM    //
//    MMMMMWXkxddxxxxxxxxxxxxxxxk0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOkkkkOKWMMMMWKkxxxxxxxxxxxxxxxddxOXWMMMMM    //
//    MMMMMMWXOxxxxxxxxxxxxxxxxxOXMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOkkkOKNWMMMMMMNOxxxxxxxxxxxxxxxdx0NMMMMMMM    //
//    MMMMMMMMN0kxxxxxxxxxxxxxxk0NMMMMMMMMMMMMMMMMMMMMMMMMMMWN0OO0KXNWMMMMMMMMN0xxxxxxxxxxxxxxxkKWMMMMMMMM    //
//    MMMMMMMMMWXOxxxxxxxxxxxxxk0WMMMMMMMMMMMMMMMMMMMMMMMMMMWNXNNWWMMMMMMMMMMMW0xxxxxxxxxxxxxk0NWMMMMMMMMM    //
//    MMMMMMMMMMMWKOxxxxxxxxxxxk0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0xkxxxxxxxxxkOXWMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWXOkxxxxxxxkkONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOxkxxxxxxxk0XWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWX0OkxxxxkxkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkxxxxxxkOKNWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWNX0OkxkkkOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkkkxxkO0XWWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWXK0OkkOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKkkkO0KXWWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWNXK00KNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXK00KXNWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AFF is ERC721Creator {
    constructor() ERC721Creator("Art For Fun", "AFF") {}
}