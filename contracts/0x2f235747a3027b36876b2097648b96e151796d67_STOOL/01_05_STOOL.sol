// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: raulonastool
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNXXKKKKKKKKKKXXXNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXK0OOkkxxxxxxxxxxxxxxkkOO0KXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK0OkxxxxxxxxxxxxxxxxxxxxxxxxxxxxkO0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWNX0kxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxk0XWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMNKOxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxOKNWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWKOxxxxxxxxxxxkOO000KKKXXXXXXXXXXXKKKK00OOkkxxxxxxxxxxxOKWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWXOkxxxxxxxxO0KXNWWWMMMMMMMMMMMMMMMMMMMMMMWWNNK0OkxxxxxxxxxOXWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWKkxxxxxxxxx0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWKkxxxxxxxxxkKWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMN0kxxxxxxxxxx0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkxxxxxxxxxxk0NMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMN0xxxxxxxxxxxxxk0KXNWWWMMMMMMMMMMMMMMMMMMMMMMWWNXK0Okxxxxxxxxxxxxx0NMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMW0kxxxxxxxxxxxxxxxxxkOO000KKKKXXXXXXXXXKKKK000OOkkxxxxxxxxxxxxxxxxxk0NMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWKkxxxxxxxxxxxxxxxxxxxxOK0000OOOOOOOOOOOOOO00000kxxxxxxxxxxxxxxxxxxxxkKWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMXOxxxxxxxxxxxxxxxxxxxxOXWMWWWWWWWWWWWWWWWWWWWWWN0xxxxxxxxxxxxxxxxxxxxxOXMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMW0xxxxxxxxxxxxxxxxxxxxx0WMNK0000KKXWWWNKK00000NWWXkxxxxxxxxxxxxxxxxxxxxx0WMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMNOxxxxxxxxxxxxxxxxxxxxkXMWKkxxxxxx0NWNKkxxxxxx0WMN0xxxxxxxxxxxxxxxxxxxxxONMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMXkxxxxxxxxxxxxxxxxxxxx0WMNOxxxxxxx0NWWKkxxxxxxkXMWKkxxxxxxxxxxxxxxxxxxxxkXMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWKkxxxxxxxxxxxxxxxxxxxkXWMNK00KKKKKXWWWNKKKKKK00XWMNOxxxxxxxxxxxxxxxxxxxxkKWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWKkxxxxxxxxxxxxxkOKKKO0NMWWNNNNNXXXNWWWWXXXXNNNNWWMWKOKKK0kxxxxxxxxxxxxxxxKWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWKkxxxxxxxxxxxk0NWWNKOKWWXOkkkkkkkk0NWNKkxkkkkkkOKWMN00XNWNKkxxxxxxxxxxxxkKWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMXkxxxxxxxxxxxkKWWWXKKNMN0kxxxxxxxx0NWNKxxxxxxxxxONMWX0KNWWXkxxxxxxxxxxxxkXMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMNOxxxxxxxxxxxxkOKXNNWMMWNNXXXXKKKKXWWWNKKKKKKXXNNWMMWWNXK0kxxxxxxxxxxxxxONMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMW0xxxxxxxxxxxxxxxxk0WMWXKKKKXXXXXXNWMMWNXXXXXKKKKKNWWKkxxxxxxxxxxxxxxxxx0WMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMXOxxxxxxxxxxxxxxxkKWWXkxxxxxxxxxk0NWWKkxkxxxxxxxx0WWXkxxxxxxxxxxxxxxxxOXMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWKkxxxxxxxxxxxxxxONMN0xxxxxxxxxxx0NWNKkxxxxxxxxxxkXMW0xxxxxxxxxxxxxxxkKWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMN0xxxxxxxxxxxxxkKWWXkxxxxxxxxxxx0NWNKkxxxxxxxxxxx0WWXkxxxxxxxxxxxxxx0NMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMN0kxxxxxxxxxxxOXMN0xxxxxxxxxxxx0NWNKkxxxxxxxxxxxOXWW0xxxxxxxxxxxxx0NMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMN0kxxxxxxxxxx0WWXkxxxxxxxxxxxx0NWNKxxxxxxxxxxxxx0WWXkxxxxxxxxxxk0NMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWKkxxxxxxxxkXWN0xxxxxxxxxxxxx0NWNKkxxxxxxxxxxxxOXWN0xxxxxxxxxkKWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWXOxxxxxxxkO0OkxxxxxxxxxxxxxkO0OkxxxxxxxxxxxxxxO00kxxxxxxxkOXWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMNKOxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxOKNMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWNKOxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxOKNMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMNX0kxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkOXNMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK0OkxxxxxxxxxxxxxxxxxxxxxxxxxxxxkO0KNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXK0OOkkxxxxxxxxxxxxxxkkOO0KXNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNNXXKKKKKKKKKKXXNNWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract STOOL is ERC721Creator {
    constructor() ERC721Creator("raulonastool", "STOOL") {}
}