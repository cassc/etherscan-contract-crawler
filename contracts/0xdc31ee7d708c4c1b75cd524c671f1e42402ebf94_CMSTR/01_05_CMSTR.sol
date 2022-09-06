// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cookie Munster
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                            ..:------::..                                         //
//                                     .-+#%@@@@@@@@@@@@@@@%.                                       //
//                                 -+%@@@@@%*+==--:::::-=%@@=                                       //
//                             .=#@@@@#+-.               [email protected]@#                                       //
//                           -#@@@#=-                     *@@=                                      //
//                         =%@@%=. [email protected]#                     *@@#-.                                   //
//                       -%@@*:     :              .=:      -%@@@@%-                                //
//                     .%@@#.                      %@@.       .-#@@+                                //
//                    [email protected]@@-                         -:          [email protected]@=                                //
//                   *@@#                                       [email protected]@*                                //
//                  #@@*                                         [email protected]@%=-:-==                         //
//                 #@@*                  :-:                       =#@@@@@@#                        //
//                [email protected]@%                 .%@@@%.                           :#@@+-::-==-               //
//               [email protected]@@:                 [email protected]@@@@+                             :+%@@@@@@@+              //
//               *@@@#:                .#@@@*                 .#*.                [email protected]@%              //
//               @@@@@@+                                       =-                 [email protected]@@:             //
//              :@@@@@@%                                                    +%%*   @@@-             //
//              [email protected]@@@@@*                                                   #@@@@=  %@@-             //
//              [email protected]@@@@*                                                    -#%%+   @@@:             //
//              [email protected]@@+.            -+-                                             :@@@.             //
//               @@@=            [email protected]@@.                                            [email protected]@#              //
//               [email protected]@%             .:                     :-                      [email protected]@@:              //
//                %@@=                                  [email protected]@+                     #@@#               //
//                [email protected]@@:                                                         [email protected]@%                //
//                 [email protected]@@.                                                       [email protected]@%.                //
//                  [email protected]@@:                                                     *@@%.                 //
//                                                                           +##*                   //
//                                                                                                  //
//               .-=++**+++********++**+**++++*++++++++++==---===----=-------:-                     //
//             =%@@@@%####*****++#@@*+++=========++++*%@@@%#####*******####%@@@.                    //
//            [email protected]@+:              [email protected]@-                 [email protected]@@*                 [email protected]@:                    //
//            @@*    .           [email protected]@#+===============+%@@@%+================#@@                     //
//            *@@[email protected]@*          [email protected]@*                [email protected]@@@@.                #@#                     //
//             -#@@@@@*           *@@*+==============%@@#@@%-------::::::::[email protected]@=                     //
//                :--.             #@@*            [email protected]@%. .%@@:.........:::*@@#                      //
//                                  -%@#=.       :[email protected]@*    .*@%=         [email protected]@*                       //
//                                    .+#@@%%%%@@@#=.       .+%@@#****#@@%+.                        //
//                                         .:--:                .-=++=-:                            //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract CMSTR is ERC721Creator {
    constructor() ERC721Creator("Cookie Munster", "CMSTR") {}
}