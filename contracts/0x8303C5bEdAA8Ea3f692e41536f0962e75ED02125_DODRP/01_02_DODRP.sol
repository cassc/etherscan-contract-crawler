// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Doodrops
// contract by: buildship.xyz

import "./ERC721Community.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//                                                                                   -#@@@@#=       //
//                                                                                 :@@@@@@@@@@=     //
//                                                                                [email protected]@@@@@@@@@@@:    //
//                                                                                [email protected]@@@@@@@@@@@+    //
//       .=+++=-                                                                  [email protected]@@@@@@@@@@@#    //
//     -%@@@@@@@@*.                                                                %@@@@@@@@@@@@    //
//    [email protected]@@@@@@@@@@@.                                                               *@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@=                                                               [email protected]@@@@@@@@@@*    //
//    %@@@@@@@@@@@@*                                 .:----:.                       [email protected]@@@@@@%+     //
//    *@@@@@@@@@@@@%                              =%@@@@@@@@@@%*-                      :-==-.       //
//    [email protected]@@@@@@@@@@@@                           :*@@@@%*+=*@@@@@@@                                   //
//     %@@@@@@@@@@@#                          [email protected]@@#-.....#@@* .:.                                   //
//     .#@@@@@@@@@%.                         %@@%[email protected]@@.                                       //
//       .=*###*=:                         .%@@*....::..*@@#                                        //
//                                         #@@@*#%@@@@@@@@@*                                        //
//                                        :@@@@@@%%#####%@@@@%+:                                    //
//                                        [email protected]@@*-::::::::::-*@@@@+                                   //
//                                        [email protected]@@-::::::::::::::+%@@*                                  //
//                                        :@@@=:::::::::::::::[email protected]@@:                                 //
//                                         %@@#::::::::::::::::@@@-                                 //
//                                         :@@@#-:::::::::::::[email protected]@@.                                 //
//                                          .%@@@#-::::::::-+%@@@:                                  //
//                                            =%@@@@%####%%@@@@*:                                   //
//                                              .=*%@@@@@@%*=:                                      //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////

contract DODRP is ERC721Community {
    constructor() ERC721Community("Doodrops", "DODRP", 1234, 1, START_FROM_ONE, "ipfs://bafybeibj7rtzavzcowrvx6sgprl3b3ecklrox7dc3at44c2ysi6x4ra76i/",
                                  MintConfig(0.009 ether, 20, 0, 0, 0xCb52Ec66F11F62c0d024dEb1E0C6A45056860c14, false, false, false)) {}
}