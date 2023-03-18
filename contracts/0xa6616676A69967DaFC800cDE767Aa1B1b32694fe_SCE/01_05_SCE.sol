// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Susano Correia - Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//                              :==*#*+-                               .-=+#**=.                    //
//                          :=#@@@@@@@@@#                          .-*%@@@@@@@@@-                   //
//                       .*@@@@@@@@@@@@@@#.                      +%@@@@@@@@@@@@@@=                  //
//                     .*@@@@@@@@@@@@@@@@@@.                   [email protected]@@@@@@@@@@@@@@@@@+                 //
//                    -%@@@@@@@@@@@@@@@@@@@%                 .#@@@@@@@@@@@@@@@@@@@@:                //
//                  -%@@@@@@@@@@@@@@@@@@@@@@:              [email protected]@@@@@@@@@@@@@@@@@@@@@*                //
//                 *@@@@@@@@@@@@@@@@@@@@@@@@+             [email protected]@@@@@@@@@@@@@@@@@@@@@@@@                //
//               [email protected]@@@@@@@@@@@+:-:-*##[email protected]@@@#           -%@@@@@@@@@@@%---:=#%*:@@@@@:               //
//            .*@@@@%+: [email protected]@@@#@@@@#++#@@@@@@         =%@@@@#-. -%@@@%#@@@%*+*@@@@@@=               //
//           [email protected]@@##-      *@@@@@@@@@@@@@@@@@@       .#@@@#+      :@@@@@@@@@@@@@@@@@@+               //
//         :#@@@*         *@@@@@@@@@@@@@@@@@@-    [email protected]@@%:        :@@@@@@@@@@@@@@@@@@%               //
//        -#%#=.          [email protected]@@@@@@@@@@@%- :@@@.   *%#*-           @@@@@@@@@@@@@+. #@@=              //
//                        [email protected]@@@*@@@@%@@=   [email protected]@%                   @@@@#%@@@%@@%   [email protected]@@:             //
//                        *@@@+ #@@+*@@+    %@@*                 :@@@@ [email protected]@@[email protected]@@    [email protected]@@.            //
//                        @@@@: %@@#*@@*    [email protected]@@:                [email protected]@@* [email protected]@@[email protected]@@     *@@#            //
//                       :@@@#  @@@%%@@#     [email protected]@%.               @@@@. [email protected]@@#@@@      %@@+           //
//                       [email protected]@@= [email protected]@@@%@@%      *@@#              [email protected]@@#  #@@@%@@@.     :@@@.          //
//                       [email protected]@@: [email protected]@@@#@@*       #@@              [email protected]@@*  *@@@#@@@       [email protected]@=          //
//                       *@@@   @@@##@@+        .:              :@@@-  [email protected]@@[email protected]@%         :.          //
//                       #@@#   @@@%%@@=                        [email protected]@@:  [email protected]@@#@@%                     //
//                       *@@*   @@@%%@@-                        :@@@   [email protected]@@#@@#                     //
//                        *%.   #@@%-*+                          =%+   [email protected]@@-**:                     //
//                              [email protected]@+                                   .%@@.                        //
//                                :                                      ..                         //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract SCE is ERC1155Creator {
    constructor() ERC1155Creator("Susano Correia - Editions", "SCE") {}
}