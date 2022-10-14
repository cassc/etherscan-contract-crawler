// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A night out in Torquay vol. 1
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////
//                                                                                //
//                                                                                //
//    ;;;;;;;;;;;;;;;;;;;;::::::::::::::::::::::::::::::::;;;;;;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;:::::::::::::::::::::::::::::::::::::::::::::::::;;;;;;;;;;;;;;    //
//    ;;;;;;;;::::::::::::::::::::::::::::::::::::::::::::::::::::::;;;;;;;;;;    //
//    ;;;;;;;;;:::::::::::::ccccccccccccc::::::::::::::::::::::::::;;;;;;;;;;;    //
//    ;;;;;;::::::::::::ccccccccccccccccccccccccccc::::::::::::::::::;;;;;;;;;    //
//    ;;;;::::::::::::cccccccccccccccccccccccccccccccccc::::::::::::::::;;;;;;    //
//    ;;::::::::::::cccccccccccccccccccccccccccccccccccccccc::::::::::::::::;;    //
//    ::::::::::::ccccccccccccccccccccccccccccccccccccccccccc:::::::::::::::::    //
//    ::::::::::cccccccccccccccclcccccccccccccccccccccccccccccc:::::::::::::::    //
//    :::::::::ccccccccccccclllcccccccccccccccccccccccccccccccccccc:::::::::::    //
//    ::::::::ccccccccccccclllclllllllllllccclccccccccccccccccccccccc:::::::::    //
//    :::::::cccccccccccllllllllllllllllllllllllclllllccccccccccccccccccc:::::    //
//    ::::::ccccccccclllllllllllllllllllllllllllllllllccllcccccccccccccccc::::    //
//    ::::cccccccccllllllllllllllllllllllllllllllllllllllllclccccccccccccc::::    //
//    ::::ccccccccllllllllllllllllllllllllllllllllllllllllcllllccccccccccc::::    //
//    ::::cccccccclllllllllllllllllllllllllllllllllllllllllllllccccccccccc::::    //
//    ::::cccccccclllllllllllllllllllllllllllllllllllllllllllllccccccccccccc::    //
//    :::cccccccclllllllllllllllllllllllllllllllllllllllllllllllccccccccccccc:    //
//    :::ccccccclllllllllllllllllllllllllllllllllllllllllllllllllcccccccccccc:    //
//    :::ccccccclllllllllllllllllloolllllllllllllllllllllllllllllcccccccccccc:    //
//    ::ccccccclllllllllllllllllllllllllllllllllllllllllllllllllllcccccccccccc    //
//    ::ccccccclllllllllllllllllllllllllllllllllllllllllllllllllllcccccccccccc    //
//    ::ccccccccclllllllllllllllllllollllllllllllllllllllllllllllllccccccccccc    //
//    ::ccccccccclllllllllllllllllllllllloooollllllllllllllllllllllccccccccccc    //
//    :::ccccccccclllllllllllllllllllllodxxxxxollllllllllllllllllccccccccccccc    //
//    :::cccccccccclllllllllllllllllllloddddddolllllllllllllllllllcccccccccccc    //
//    ::::cccccccccclllllllllllllllllllllllllllllllllllllllllllllllccccccccccc    //
//    ::::ccccccccccccllllllllllllllllllllllllllllllllllllllllllllcccccccccccc    //
//    ::::ccccccccccccllllllllllllllllllllllllllllllllllllllllllcccccccccccccc    //
//    ::::cccccccccccclccllllllllllllooooddoodoooolllllllllllllccccccccccccccc    //
//    :::::cccccccccccccccllllllloodddxddxxxxxddddddolllllllllcccccccccccccccc    //
//    :::::ccccccccccccccclllllloddxxxxxxdddxxxxxddddollllllllcccccccccccccccc    //
//    ::::ccccccccccccccccllllllldxxxxxxxddddddddddddollllllllcccccccccccccccc    //
//    :::cccccccccccccccccclllllllodddddddooooddxddoolllllllllcccccccccccccccc    //
//    :::::cccccccccccccccccccllllllloooooooooooolllllllllllllcccccccccccccccc    //
//    ::::ccccccccccccccccccccllllllllllllllllllllllllllllllllcccccccccccccccc    //
//    ::::cccclccccccccccccccclllllllllllllllllllllllllllllllllccccccccccccccc    //
//    :::ccccllcccccccccccccclllllllllllllllllllllllllllllllllllcccccccccccccc    //
//    :::cccccllccccccccccccccllllllllllllllllllllllllllllllllllcccccccccccccc    //
//    ::cccllloollccccccccccccllllllllllllllllllllllllllllllllllcccccccccccccc    //
//    cccccllooddlccccccccccclllllllllllllllllllllllllllllllllllcccccccccccccc    //
//    cccccloollllccccccccllllllllllllllllolllllloollllllllllccccccccccccccccc    //
//    cccccllcccclccccllllloolloodxxdoodxxkxxdddxkkkdoooddolllllccccccccclllll    //
//    :cccccccccccccloooddxkkxxkkkkkkkkkkkkkkkkkkkkkkkxxkxxxdddddolllcclllllll    //
//    :::cccccccclodxxkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxkkkxxxxxxxxxxxdddollllllll    //
//    c::::::cclloxxxxxxxxxxxxkkkkkkkkkkkkkkkkkkxxkxxxkkxxxxxxxdddddddolllooll    //
//    lc::::ccllloddddxxxxxxxkkkxkkkxxkkkxdxxkkxdxkkxxxkxdxxxdxddddddoollooool    //
//    ll:::::ccllloddddxxxkxdxkxddxkxxxkkxodxkkxdxxxddxxddxxddxdddddoooooooooo    //
//                                                                                //
//                                                                                //
////////////////////////////////////////////////////////////////////////////////////


contract TV1 is ERC721Creator {
    constructor() ERC721Creator("A night out in Torquay vol. 1", "TV1") {}
}