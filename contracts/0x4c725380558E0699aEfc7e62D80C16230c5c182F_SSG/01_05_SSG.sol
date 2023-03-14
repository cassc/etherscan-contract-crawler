// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Slow Shrug ETH Genesis
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//              .+%%##*-.                                                                           //
//            .*@@@@@@@@@=                                                           .::.           //
//           [email protected]@@@@@@@@@@#   :=+++:           -+#@@@@%#+.       #%###-    %@@%.    %@@@@@           //
//          [email protected]@@@@@#+*@@*   [email protected]@@@@#         -%@@@@@@@@@@@#     [email protected]@@@@*   [email protected]@@@%   :@@@@@*           //
//          [email protected]@@@@@-  .:    [email protected]@@@@+        [email protected]@@@@@@@@@@@@@+    :@@@@@-   #@@@@@:  [email protected]@@@@=           //
//           *@@@@@@@*:    [email protected]@@@@@.        %@@@@@@@@@@@@@@@=   [email protected]@@@@   [email protected]@@@@@-  %@@@@@-           //
//            @@@@@@@@@*.  [email protected]@@@@+       [email protected]@@@@@%=:[email protected]@@@@@:   %@@@@- [email protected]@@@@@@. [email protected]@@@@#            //
//            :#@@@@@@@@%. [email protected]@@@@-       %@@@@@+      *@@@@@=   [email protected]@@@@#@@@@@@@@**@@@@@#             //
//           .   -#@@@@@@# [email protected]@@@@:       %@@@@@       %@@@@@+   [email protected]@@@@@@@@@@@@@@@@@@@@:             //
//          *@#: [email protected]@@@@@@ #@@@@@=       *@@@@@.     [email protected]@@@@@.    @@@@@@@@@-.#@@@@@@@@*              //
//         *@@@@@@@@@@@@@- @@@@@@        [email protected]@@@@#    [email protected]@@@@@=    [email protected]@@@@@@@+   @@@@@@@@=              //
//         %@@@@@@@@@@@%. [email protected]@@@@@#+==+.   %@@@@@@#*%@@@@@@@     :@@@@@@@%   [email protected]@@@@@@@-              //
//          =#@@@@@@@@*   [email protected]@@@@@@@@@@:   *@@@@@@@@@@@@@@@-      %@@@@@@.    @@@@@@@#               //
//            .:=+*=:     :@@@@@@@@@@%    .%@@@@@@@@@@@@#:       *@@@@@%     %@@@@@#                //
//                        [email protected]@@@@@@@@@=      -#@@@@@@@%+:         .%@@%@=     :****=                 //
//          .:::.          :::::---:..:        :---.                                                //
//       -%@@@@@@@#-    .:---     *@@@@%   .:-=++++++=-                                             //
//      *@@@@@@@@@@+   [email protected]@@@@     @@@@@#  #@@@@@@@@@@@@%:              :+===.        .:-:.          //
//     *@@@@@@@@@@@.   *@@@@@.   [email protected]@@@@#  #@@@@@@@@@@@@@@-   +##@@-    %@@@@+     =%@@@@@@@@#:      //
//     @@@@@@#..=+:    #@@@@@    [email protected]@@@@#  %@@@@@@*#@@@@@@%  [email protected]@@@@=   [email protected]@@@@*   .%@@@@@@@@@@@@+     //
//     #@@@@@@+        [email protected]@@@@=  .*@@@@@#  @@@@@@-  [email protected]@@@@@  [email protected]@@@@=    @@@@@=  :%@@@@@@@@@@@@@%.    //
//     [email protected]@@@@@@@*-     [email protected]@@@@@@@@@@@@@@@  #@@@@@=  :@@@@@@  [email protected]@@@@=   [email protected]@@@@=  %@@@@@@+--+**=:      //
//      #@@@@@@@@@#:   *@@@@@@@@@@@@@@@@  #@@@@@@##@@@@@@+  [email protected]@@@@=   [email protected]@@@@@+#@@@@@@:              //
//       =%@@@@@@@@@-  %@@@@@@@@@@@@@@@@  *@@@@@@@@@@@@@#   :@@@@@-   [email protected]@@@@@@@@@@@@*   .-=+**+:    //
//         .=+%@@@@@%  %@@@@@@%%%@@@@@@@  [email protected]@@@@@@@@@@@=    [email protected]@@@@-   [email protected]@@@@@@@@@@@@-  [email protected]@@@@@@#    //
//     =%=    [email protected]@@@@@  @@@@@@=   :@@@@@@  #@@@@@@@@@@@@     [email protected]@@@@+   :@@@@@@@@@@@@@*   @@@@@@@*    //
//    [email protected]@@@#*%@@@@@@#  @@@@@@=   [email protected]@@@@@  [email protected]@@@@%#@@@@@*    [email protected]@@@@=   [email protected]@@@@@#@@@@@@%   :[email protected]@@@@*    //
//    [email protected]@@@@@@@@@@@@:  *@@@@@:    @@@@@@  #@@@@@- [email protected]@@@@:   :@@@@@%-:[email protected]@@@@@= [email protected]@@@@@+    *@@@@*    //
//    .+%@@@@@@@@@%-   #@@@@@     @@@@@%  %@@@@@.  #@@@@#    @@@@@@@@@@@@@@%   [email protected]@@@@@%#*#@@@@@+    //
//       :+#%%@%*-     %@@@@@     -===-.  %@@@@%    *%%#*.   [email protected]@@@@@@@@@@@@:    *@@@@@@@@@@@@@@=    //
//                     .-...              :-:.                :%@@@@@@@@@%-      [email protected]@@@@@@@@@@%-     //
//                                                              -+#@%##+:          -#@@@@%#+-       //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract SSG is ERC1155Creator {
    constructor() ERC1155Creator("Slow Shrug ETH Genesis", "SSG") {}
}