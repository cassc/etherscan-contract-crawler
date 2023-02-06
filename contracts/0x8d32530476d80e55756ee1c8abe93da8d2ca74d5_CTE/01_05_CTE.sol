// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Checks - TokenSmart Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOxddddxOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK0kxddooddddxk0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKOxddooooooooooodddxOKNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNX0kxddooooooooooooooodooddxk0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWXKOxddooooooooodoooooooooooddooodxkOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWNX0kxddooooooooooooodooooooooooooooooooddxO0XWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWXKOkddoooooooooooooooooooooooooooooooooooooooodxk0KNWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWNX0kxddoodoooooooooooooooooooooooooooooooooooooooooooddxOKXWWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWNKOkddoooooooooooooooooooooooooooooooooooooooooooooooooooooodxk0XNWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWNX0kxddooooooooooooooooooooooooooooooooooooooooooooooooooddoodoooooddxOKNWMMMMMMMMMMMMM    //
//    MMMMMMMMMWNKOkddooooooooooooodoooooooddddooooooooooooooooooodddooooooodddooooodooooodxk0XNWMMMMMMMMM    //
//    MMMMMWNX0OxddoooooooooooooooooddddddkOKKOdooooooooooooodddxO0KOkxddooooooooooooooooooodddxOKNWMMMMMM    //
//    MMMWX0kxdooodoooooooooooooooooddxO0XNWMMNOdoooooooooooododkXMMWWXKOxddooooooooooodooooooooddxO0XWMMM    //
//    MMMXkdooddodooodoooooooooodddkOKNWMMMMMMNOxoooooooooooooodONMMMMMMWNKOkdddoodooooodddooooooooodkXMMM    //
//    MMMWX0kddooooooooooooooddxk0XNWMMMMWMMMMNOdoooooooooooooodONMMMMWMMMMWNX0OxddooooooooooooooddxkKNMMM    //
//    MMMMMWNX0kxddoodooodddxOKNWMMMMWWNXXNWMMNOdoooooooooooooodONMMMNXXNWWMMMMWNKOkdddoooooodddkOKNWMMMMM    //
//    XKXNWMMMMWXKOxddodxk0XNWMMMMWNXXKK0KXWMMNOxoooooooooooooodONMMWXK0KKXXNWMMMMWNX0kxdoodxk0XNWMMMWNKKX    //
//    doodk0XWWMMMWNK00KXWMMMMWWNXKKK0000KXWMMNOxoooooooooooooodONMMWXK00000KKXNWWMMMMWNK00KXWMMMWNX0kdood    //
//    lllloodxOKNWMMMMMMMMMWNNXKK00000000KXWMMNOxoooooooooooooodONMMWXK00000000KKXNNWMMMMMMMMMWNKOxdollloo    //
//    llllllllooxk0NWMMMMWXKKK00000000000KXWMMNOxoooooooooooooodONMMWXK00000000000KKKXNWMMMWX0kdoolllllloo    //
//    llllllllllllokNMMMWXK00000000000000KXWMMNOxoooooooooooooodONMMWXK00000000000000KXWMMMXxoollllllllloo    //
//    lllllllllllloxXMMMNXK00000000000000KXWMMNOdoooooooooooooodONMMWXK00000000000000KXWMMMXdllllllllllllo    //
//    lllllllllllloxXMMMNXK0000000000000KKNWMMW0kxxxxxxxxxxxxxxk0NMMWNXKKKKKKKKKKKKKKXNWMMMXdlllllllllllll    //
//    lllllllllllloxXMMMNXK000000000000KNWMMMMMWNNNNNNNNNNNNNNNWWMMMMMWWWWWWWWWWWWWWWMMMMMMXdlllllllllllll    //
//    lllllllllllloxXMMMNXK000000000000KNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMMMMMMMMXdlllllllllllll    //
//    lllllllllllloxXMMMNXK000000000000KKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNNWMMMMXdlllllllllllll    //
//    lllllllllllloxXMMMNXK000000000000000000000000000000000000000000000000000000000KKNWMMMXdlllllllllllll    //
//    lllllllllllloxXMMMNXK0000000000000000000000000000000000000000000000000000000000KXNMMMXdlllllllllllll    //
//    lllllllllllloxXMMMNXK0000000000000000000000000000000000000000000000000000000000KXNMMMXdlllllllllllll    //
//    lllllllllllloxXMMMWXK00000000000000000000000000000000000000000000000000000000000XNMMMXdlllllllllllll    //
//    lllllllllllloxXMMMMNXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0000000000000KXNMMMXdlllllllllllll    //
//    lllllllllllloxXMMMMMMWNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXK00000000000KXNMMMXdlllllllllllll    //
//    lllllllllllloxXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX00000000000KXNMMMXdlllllllllllll    //
//    lllllllllllloxXMMMMWNNNNNNNNNNNNNNNNWMMMWNXXXXXXXXXXXXXXXXNWMMMWNNXK00000000000KXNMMMXdlllllllllllll    //
//    lllllllllllloxXMMMWXKKK00000000KK0KKXWMMNOxddddddddddddddx0NMMWXK00000000000000KXNMMMXdlllllllllllll    //
//    lllllllllllloxXMMMNXK00000000000000KXWMMNOdoooooooooooooodONMMWXK00000000000000KXNMMMXdlllllllllllll    //
//    lllllllllllloxXMMMWXKK0000000000000KXWMMNOdooooooooooooooxONMMWXK0000000000000KKNWMMMXdlllllllllllll    //
//    llllllllllllldKWMMMWWNXKKK000000000KXWMMNOdooooooooooooooxONMMWXK0000000000KKXNWWMMMW0dlllllllllllll    //
//    lllllllllllllodOXNMMMMWWNXKKK000000KXWMMNOdooooooooooooooxONMMWXK0000000KKXNWWMMMWNXOdollllllllllloo    //
//    lllllllllllllllodxOKNWMMMMWNNXKK000KXWMMNOdooooooooooooooxONMMWXK000KKXNNWMMMMWNKOxdoolllllllllllooo    //
//    oollllllllllllllllooxOKXNWMMMWWNXKKKXWMMNOdoooooooooooooodONMMWXKKKXNWWMMMMNX0kdoolllllllllllllllloo    //
//    xolllllllllllllllollloodxOXNWMMMMWNNWMMMNOdoooooooooooooodONMMMWNNWMMMMWNKOxdoolllllllllllllllllllox    //
//    XkdoollllllllllllllllllllodxOKNWMMMMMMMMNOdoooooooooooooox0NMMMMMMMMWX0kxoolllllllllllllllllllllodOX    //
//    MWX0kdooollllllllllllllllllooodk0XNWMMMMWN0kxddooooodddxOKNWMMMMWNX0xdooollllllllllllllllllloodk0XWM    //
//    MMMMWXKOxdolllllllllllllllllllllodxOKNWMMMMWNKOkxxxxk0XNWMMMMWX0kxdolllllllllllllllllllllodxOKNWMMMM    //
//    MMMMMMMWNX0kdoolllllllllllllllllllloodk0XNWMMMMWXXXNWMMMMWNX0kdoolllllllllllllllllllloodk0XNWMMMMMMM    //
//    MMMMMMMMMMMWXKOxdolllolllllllllllllllllodxOKNWMMMMMMMMWXKOxdolllllllllllllllllllllodxOKXWMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWNX0kdoolllllllllllllllllllooodk0XNNNNX0kdoollllollllllllllllllloodx0XNWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWX0kxoollllllolllllllllllllooddxxddolllllllllllllllllllllooxk0XWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWNKOxdoolllllllllllllllllllllllllllllllllllllllllooodxOKNWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWWX0kxoollllllllllllllllllllllllllllllllllllooxk0XNMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOxdoolllllllllllllllllllllllllllloodxOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNX0kdoolllllllllllllllllllllloodk0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKOxdollllllllllllllloodxOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNX0kdoolllllllloodk0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0OxdoooodxOKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK0000KXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CTE is ERC1155Creator {
    constructor() ERC1155Creator("Checks - TokenSmart Edition", "CTE") {}
}