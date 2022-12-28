// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Meta Mutants Club - Crunks
// contract by: buildship.xyz

import "./ERC721Community.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                     //
//                                                                                                     //
//          MMMMMMMM               MMMMMMMMMMMMMMMM               MMMMMMMM        CCCCCCCCCCCCC        //
//          M:::::::M             M:::::::MM:::::::M             M:::::::M     CCC::::::::::::C        //
//          M::::::::M           M::::::::MM::::::::M           M::::::::M   CC:::::::::::::::C        //
//          M:::::::::M         M:::::::::MM:::::::::M         M:::::::::M  C:::::CCCCCCCC::::C        //
//          M::::::::::M       M::::::::::MM::::::::::M       M::::::::::M C:::::C       CCCCCC        //
//          M:::::::::::M     M:::::::::::MM:::::::::::M     M:::::::::::MC:::::C                      //
//          M:::::::M::::M   M::::M:::::::MM:::::::M::::M   M::::M:::::::MC:::::C                      //
//          M::::::M M::::M M::::M M::::::MM::::::M M::::M M::::M M::::::MC:::::C                      //
//          M::::::M  M::::M::::M  M::::::MM::::::M  M::::M::::M  M::::::MC:::::C                      //
//          M::::::M   M:::::::M   M::::::MM::::::M   M:::::::M   M::::::MC:::::C                      //
//          M::::::M    M:::::M    M::::::MM::::::M    M:::::M    M::::::MC:::::C                      //
//          M::::::M     MMMMM     M::::::MM::::::M     MMMMM     M::::::M C:::::C       CCCCCC        //
//          M::::::M               M::::::MM::::::M               M::::::M  C:::::CCCCCCCC::::C        //
//          M::::::M               M::::::MM::::::M               M::::::M   CC:::::::::::::::C        //
//          M::::::M               M::::::MM::::::M               M::::::M     CCC::::::::::::C        //
//          MMMMMMMM               MMMMMMMMMMMMMMMM               MMMMMMMM        CCCCCCCCCCCCC        //
//                                                                                                     //
//                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////

contract CRUNKS is ERC721Community {
    constructor() ERC721Community("Meta Mutants Club - Crunks", "CRUNKS", 3333, 333, START_FROM_ONE, "ipfs://bafybeieq34hbnhxbwaaqcx2tawmuui55t2j34uzdcn5bciwyi5g7nfpxpa/",
                                  MintConfig(0 ether, 3, 3, 0, 0x39F9E965AcE273FdD8DAA5Bc4f86205A629aC8B8, false, false, false)) {}
}