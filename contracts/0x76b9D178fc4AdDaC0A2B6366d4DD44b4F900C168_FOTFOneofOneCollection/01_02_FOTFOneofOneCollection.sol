// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// name: Fury of the Fur 1/1 Collection
// contract by: buildship.xyz

import "./ERC721Community.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                     .:-------------------::.                                     //
//                              .-===--:.                   ..:--===:                               //
//                .:.       .-==-.                                  .-==-.      .-:.                //
//              ==:.:=+   ==-                                            -==. -+: .-+-              //
//            :*. .:   *+=                                                  -*=   :. .+.            //
//           -+  *@@@:                -=-                    -=-                :@@@#  +-           //
//          :*  #@@@=                *@@@#                  #@@@#                [email protected]@@%  +-          //
//          #  [email protected]@@:                 @@@@%                  @@@@@                 [email protected]@@.  #          //
//          #    ::                  @@@@@                 [email protected]@@@@                  ::   .*          //
//           +=.                    [email protected]@@@@.                :@@@@@.                   .:==           //
//             :-*=                 :@@@@@.                [email protected]@@@@:                 -*:.             //
//               *.                 [email protected]@@@@:                [email protected]@@@@:                  #               //
//               #                  [email protected]@@@@-                [email protected]@@@@-                  *.              //
//               #                  [email protected]@@@@=                [email protected]@@@@=                  =-              //
//              .*                  [email protected]@@@@=                [email protected]@@@@=                  :+              //
//              :+                  [email protected]@@@@+                *@@@@@+                  .*              //
//              .*                  *@@@@@+                *@@@@@+                   *              //
//               #                  *@@@@@*                *@@@@@*                  .*              //
//               #                  #@@@@@*                #@@@@@*                  :+              //
//               +:                 #@@@@@#                #@@@@@#                  =-              //
//               .*                 #@@@@@#                #@@@@@#                  #               //
//                *.                %@@@@@%                %@@@@@%                 :+               //
//                .*                %@@@@@%                %@@@@@%                 *.               //
//                 -=               %@@@@@%                %@@@@@@                ==                //
//                  ==              %@@@@@@                %@@@@@@               :+                 //
//                   -+             *####%%                *###%%%              -+                  //
//                    :+.                                                      +-                   //
//                      +=                                                   :+.                    //
//                       .+=                                               :+-                      //
//                          -=-                                         .==:                        //
//                             -==:                                 .-==:                           //
//                                .-===-:.                    .--===:                               //
//                                      .:--------------------:                                     //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////

contract FOTFOneofOneCollection is ERC721Community {
    constructor() ERC721Community("Fury of the Fur 1/1 Collection", "FOTF11", 100, 74, START_FROM_ONE, "ipfs://bafybeifle5tp2qr7ynpuy3zb7jz2mgac6j4azdnscapdf4axhr7xfgirgu/",
                                  MintConfig(0.1 ether, 3, 3, 0, 0x352F6Aa85C8584FC29aDDA8Ee31FAf051495528d, false, false, false)) {}
}