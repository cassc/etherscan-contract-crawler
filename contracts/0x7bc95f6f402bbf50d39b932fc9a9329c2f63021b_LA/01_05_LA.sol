// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Los Angelo
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0OXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKOxdkNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK0xdood0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOxooooooxXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOdoooooodoxXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOxoooooooodoxXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxdoooooooooooxKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOdodoooooooooood0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkooooooooooooooookNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxoodoodoooooooooood0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxodooddoooooooooooooxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxooddododooooooooooodokNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXxoooooooooooooooooooooodONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXkoooooooooooooooooooooooddONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOoodoooooooooooooooooooodoodkNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWWWMMMMMMMW0dooooooooooooooooooooooodooddkXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMN0ONMMMMMMMXxodooooooooooooooooooooooooodooxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMNOdkNMMMMMMWOdoodoodoooooooooooooooooooooooood0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMNkdokNMMMMMMXxooooooooooooooooooooooooooooooooddkXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMNkdooxXMMMMMWOdoooooooooooooooooooooooooooooooooooxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMNOdododKWMMMMXxooooooooooooooooooooooooooooooooooooodONMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMW0doooooOWMMMMKdoooooooooooooooooooooooooooooooooodooooxKWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMXxoooodoxXWMMWOooooooooooooooooooooooooooooooooooooodooodkXWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMNOooooooooONMMNkodoodoooooooooooooooooooooooooooooooooooooox0WMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMKdoddooodod0WMXxoooooooooooooooooooooooooooooooooooodooooooodONMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWOoodooooooodONKxooooooooooooooooooooooooooooooooooooooooodooodkNMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMNkodooooooooodkOdoooooooooooooooooooooooooooooooooooooooooooodooONMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMKxodooooodoooooddooooooooooooooooooooooooooooooooooooooooooodooodOWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMKdodooooooooooodoooooooooooooooooooooooooooooooooooooooooooooodoodKMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMKdodooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooookNMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMKxodoooooooooooooooooooooooooooooooooooooooooooooooooooooooooooodod0WMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMXkodoooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooookNMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWOooooooodoooooooooooooooooooooooooooooooooooooooooooooooooooooooooxXMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMKdooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooood0WMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMNkodoodooooooooooooooooooooooooooooooooooooooooooooooooooooooooooodOWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMKxodooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooOWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMW0dodoooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooOWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMNOdooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooOWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMNOdoodoooooooooooooooooooooooooooooooooooooooooooooooooooooooood0WMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMNOdooooooooooooooooooooooooooooooooooooooooooooooooooooooooooodKMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMNOdooodoodoooooooooooooooooooooooooooooooooooooooooooooooooookXWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWKxoooooooooooooooooooooooooooooooooooooooooooooooodooddoood0WMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWXkdoooooooooooooooooooooooooooooooooooooooooooooooooooodoxXMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMW0xdoooooooooooooooooooooooooooooooooooooooooooooodooood0WMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWN0xoodooddooooooooooooooooooooooooooooooooooooooooddokNMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWN0xdodooooooooooooooooooooooooooooooooooooooooooookXMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKkdooooooooooooooooooooooooooooooooooooooooodoxXWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWKkdooooooooooooooooooooooooooooooooooooooodxXWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOdoooooodooooooooooooooooooooooddooododkXWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkdoooooooooooooooooooooooooodoooddodONMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxdoodoooooooooooooooooooooooodooxKWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkdooooooooooooooooooooooooododOXWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOdoooooooooooooooooodooooodkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOdooooooooooooooodooooodkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXxodooooooooooooooooodkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0dooooooooooooooooxOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKdoooooooooooodxkKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXxodoooooooddk0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXxoooooodxOKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKxodxkO0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXO0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWX0OOOO0OO000OO0O0OO00OOOO00OOO0OOOOOOO0OOOOOOOOO0KNMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMM0lcc::cccc:cccccccccccc:ccc:cccccccccccccccccccccccxNMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMOccccccccccccccclllcccccccccccccclolcccccccccccccc:oXMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMOcccccccccccccd0XNKxlcccccccccclkXNXOocccccccccccc:oXMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMOcccccccccccccOMMMMKo:cccccccc:dNMMMWkcccccccccccc:dXMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMOcccccccccccccoOKK0dcccccccccc:lx0XKklcccccccccccc:dXMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMOcccccdO0OxlcccccccccclxO00Odc:cccccccccoO00xlcccc:dXMMMMMMMMMMMMMMMMMMMMMMM    //
//    WX000000000000000NMMMMMMOccccdXMMMWkcccccccccckWMMMMXd:ccccccc:oKMMMWOcccc:dXMMMMMMMMMMMMMMMMMMMMMMM    //
//    Xd:cccccccccccccckWMMMMMOccc:lONWNKdccccccccccdKNWWNOlcccccccc:lONWNKdcccc:oXMMMMMMMMMMMMMMMMMMMMMMM    //
//    Ko:cccccccccccccckWMMMMMOccccccodolccccoxxdlcccloddoccccldxxlccccodolccccc:dXMMMMMMMMMMMMMMMMMMMMMMM    //
//    Nkooooooooooooooo0WMMMMMOcccccccccccccxNWMW0lccccccccccoKWMWXdcccccccccccc:oXMMMMMMMMMMMMMMMMMMMMMMM    //
//    MWNNNNNNNNNNNNNNWWMMMMMWOccccccccccccckWMMW0l:cccccccc:oXMMMNxcccccccccccc:oXMMMMMMMMMMMMMMMMMMMMMMM    //
//    NK000000000000000000000kocccccccccccccldkOxlccccccccccccokkkdcccccccccccccccdO00000000000000000000KN    //
//    dccccccccccccccccccccccccccccccccccccccccccccccccccccccccc:ccccccccccccccccccccccccccccccccccccccccd    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccclllllllcc:cccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccccoxkO0KXXXNNXXKKOkxoccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccclxOKNWMMMMMMMMMMMMMMMWNKOdlccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccokXWMMMMMMMMMMMMMMMMMMMMMMMWXkoccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccoONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNklccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccxXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKdcccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccckNMMMMMMMMMMMNKOkxxxxxkOKNMMMMMMMMMMMNxccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccxNMMMMMMMMMWXkoccccccc::ccokXMMMMMMMMMMNxcccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccoXMMMMMMMMMNOlccccccccccccccclONMMMMMMMMMKo:cccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccOWMMMMMMMMWkccccccccccccccccccckWMMMMMMMMWkccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccc:lKMMMMMMMMMKl:ccccccccccccccccc:oKMMMMMMMMM0l:ccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccc:lKMMMMMMMMM0ccccccccccccccccccccl0MMMMMMMMMKl:ccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccl0MMMMMMMMMKl:ccccccccccccccccc:oKMMMMMMMMM0lcccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccOWMMMMMMMMWkcccccccccccccccccccOWMMMMMMMMWkccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccoXMMMMMMMMMWOlcccccccccccccccoOWMMMMMMMMMKo:cccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccxNMMMMMMMMMWXkdl::cccccccldOXMMMMMMMMMMNxcccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccxNMMMMMMMMMMMWK0kkxxkkk0XWMMMMMMMMMMMNxccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccdXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKdcccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccclkXMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXklccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccokXWMMMMMMMMMMMMMMMMMMMMMMMWKkoccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccldOKNWMMMMMMMMMMMMMMMWNKkdlccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccccodkO0KXXXXXXXK0Okdoccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccc:ccccllllllcc:cccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    klcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccclk    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LA is ERC1155Creator {
    constructor() ERC1155Creator("Los Angelo", "LA") {}
}