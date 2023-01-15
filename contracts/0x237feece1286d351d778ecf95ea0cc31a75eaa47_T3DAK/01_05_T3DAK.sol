// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 3Bak in 3D
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                   .                                                        //
//                                                  [email protected]                                                       //
//                                                 [email protected]@:                                                       //
//                                                [email protected]@@                                                        //
//                                               [email protected]@@%                                                        //
//                                              #@@@@=                                                        //
//                                            .%@@@@@                                                         //
//                                           [email protected]@@@@@+      :-+##%@@@@%#=.                                     //
//                                          [email protected]@@@@@#  .=*%@@@@@@@@@@@@@@@*                                    //
//                                        .#@@@@@@@+#@@@@@@@@@@@@@@@@@@@@@*                                   //
//                                       [email protected]@@@@@@@@@@@@@@@@@@@@@%%%%@@@@@@@                                   //
//                                      *@@@@@@@@@@@@@%#+=-:.      [email protected]@@@@@#                                   //
//                                     *@@@@@@@@@%*-.             :%@@@@@@:                                   //
//                                     %@@@@@@*-.                [email protected]@@@@@@=                                    //
//                                     @@@@%-                  [email protected]@@@@@@@=     .::----::.                      //
//                                      .:.                  [email protected]@@@@@@@%:.=*%@@@@@@@@@@@@@%+:                  //
//                                                         -%@@@@@@@@@#@@@@@@@@@@@@@@@@@@@@@%=                //
//                                                       =%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@=              //
//                                                     =%@@@@@@@@@@@@@@@@@@@@%#*+++++*#@@@@@@@@@#             //
//                                                   :%@@@@@@@@@@@@@@@#*=-.             :[email protected]@@@@@@*            //
//                                                  [email protected]@@@@@@@@@@#+=:                      .#@@@@@@-           //
//                                                   @@@@@@#=:.                             %@@@@@@           //
//                                                    =#*-.       ==:              .-       [email protected]@@@@@=          //
//                                                               [email protected]@@+          :*@@+        @@@@@@%          //
//                               -*%@@@@@@#=                     :@@@@%.      .#@@@#         *@@@@@@          //
//                            [email protected]@@@@@@@@@@@@+         -#:        @@@@@%    .*@@@@*          [email protected]@@@@@-         //
//                         =%%@@@@#[email protected]@@@@@%         :@@.       *@@@@@-  [email protected]@@@%-           :@@@@@@=         //
//                        .%@@@%=     *@@@@@@=        .%@@%       :@@@@@*.%@@@@@@@@@@@%#+:   :@@@@@@+         //
//                       [email protected]@@@@     :%@@@@@@*         [email protected]@@@#       %@@@@@@@@@@@@@@@@@@@@@@-  :@@@@@@=         //
//                     :%@@*@@@+  .*@@@@@@@*          *@@@@@+      [email protected]@@@@@@@+. :=*#@@@@@@@=  [email protected]@@@@@-         //
//                    [email protected]@+  @@@@[email protected]@@@@@@@@*#%%%#*-   %@@@@@@-      %@@@@@+        [email protected]@@@@@+  [email protected]@@@@@.         //
//                   [email protected]#.   *@@@@@@@@@@@@@@@@@@@@@@@: @@@%*@@@:     [email protected]@@@          :@@@@@@=  @@@@@@%          //
//         =         :-     [email protected]@@@@@@@@@+-..   :%@@@@[email protected]@@[email protected]@@@.    :@@@@-         [email protected]@@@@@- #@@@@@@-          //
//         %:               :@@@@@@@@*.       [email protected]@@@@:[email protected]@@  [email protected]@@@.    %@@@+         [email protected]@@@@@:[email protected]@@@@@*           //
//         #+                @@@@@*=.       :#@@@@@+ %@@* [email protected]@@@@.   [email protected]@@#         [email protected]@@@@@*@@@@@@#            //
//         [email protected]               @@@@@-       .*@@@@@@* [email protected]@@*%@@@@@@@%.   %@@#         [email protected]@@@@@@@@@@@%             //
//         :@#               #@@@@*     :*@@@@@@@+  [email protected]@@@@@%.%@@@@%   :@@+         [email protected]@@@@@@@@@@%.             //
//          %@#              *@@@@@   -#@@@@@@@@-=*%@@@@%+-  :@@@@@*   [email protected]=         [email protected]@@@@@@@@@#.              //
//          [email protected]@%.            [email protected]@@@@[email protected]@@@@@@@@*  [email protected]@@@%       *@@@@*    #.         [email protected]@@@@@@@@+                //
//           %@@@-           [email protected]@@@@@@@@@@@@@%:    [email protected]@=        #@@@-             [email protected]@@@@@@@@:                 //
//           [email protected]@@@*           [email protected]@@@@@@@@@@#-       [email protected]%          -#@            -#@@@@@@@@@*                   //
//            [email protected]@@@%-          [email protected]@@@@@@#+.         [email protected]                      -*@@@@@@@@@@@@.                   //
//             [email protected]@@@@%=          .  .              -*                    -*@@@@@@@@@@@@@@@.                   //
//              [email protected]@@@@@@+.                                           :=#@@@@@@@@@@@@@@@@@@.                   //
//               [email protected]@@@@@@@%+-:                                  .-+#@@@@@@@@@@@@%+:[email protected]@@@@@.                   //
//                .*@@@@@@@@@@@#*+=-:.                    .:=*%@@@@@@@@@@@@@@@*:   [email protected]@@@@@.                   //
//                  :*@@@@@@@@@@@@@@@@@@%%##**********#%%@@@@@@@@@@@@@@@@@#+:      [email protected]@@@@@.                   //
//                    .=#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#+:          [email protected]@@@@@:                   //
//                        -+#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#+-.              [email protected]@@@@@:::-===-:           //
//                             :-=+*#%@@@@@@@@@@@@@@@@@@@%#*+=:.                    =%@@@@@@@@@@@@@#          //
//                                        .....:::....                                  :-%@@@@@@@@:          //
//                                                                                 .=*%@@@@@@@@@@@:           //
//                                                                               [email protected]@@@@@@@@@@@@@+             //
//                                                                               [email protected]@@@@@@@@@%+:               //
//                                                                                #@@@@@@@@@:                 //
//                                                                                 [email protected]@@@@@@@=                 //
//                                                                                    @@@@@@.                 //
//                                                                                    #@@@@*                  //
//                                                                                    [email protected]@@*                   //
//                                                                                     @@=                    //
//                                                                                     -.                     //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract T3DAK is ERC721Creator {
    constructor() ERC721Creator("3Bak in 3D", "T3DAK") {}
}