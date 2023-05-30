// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BekaRios
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//              :-                                :#=:                          =+           ..:.                                                               //
//             #@@@-                 .-:. .:--:.  #@@@@*.      --              *@@+     -***#@@@@*+-    [email protected]@#         ...                 .+*##+#**.             //
//            [email protected]@@@%%#@@@@#+.       .%@%%@@@@@@@. [email protected]@@@@#     *%@-            [email protected]@@%    #@@@@@@@@@@@@#    .:        *@@@@@#+:.           [email protected]@@@@@@@@@@.           //
//            [email protected]@@@@%*=*@@@@@-      :@@@@@@@@@@#- [email protected]@@@@%    [email protected]@@=           [email protected]@@@@-   @@@@@@@@@@@@@@:  -=-:      %@@@@@@@@@@*++       [email protected]@@@@@@@@@@@#           //
//            :@@@@@:   [email protected]@@@%       @@@@@@%=..   [email protected]@@@@=  -*@@@%:         :#@@@@@@%   #@@@@@*-:@@@@@- [email protected]@@+     *@@@@@%%@@@@@@-      [email protected]@@@@@%#@@@@@@:          //
//            .%@@@@=  [email protected]@@@@+       @@@@@@.      :@@@@@-:[email protected]@@@@=         [email protected]@@@@@@@%   *@@@@@  [email protected]@@@@+ [email protected]@@.    [email protected]@@@%:  -%@@@@@+     [email protected]@@@@@-  .=**=.          //
//            :#@@@@%=#@@@@@#        #@@@@@*-.-=- [email protected]@@@@@@@@@@#:         *@@@@@@@@@@-  *@@@@@.:@@@@@@+ [email protected]@@    [email protected]@@@@.      :#@@@-     [email protected]@@@@@=                 //
//            :[email protected]@@@@@@@@@@@@@.      #@@@@@@@@@@+ [email protected]@@@@@@@@@#          *@@@@@*[email protected]@@@=  *@@@@@@@@@@@@-  [email protected]@@    [email protected]@@@#        [email protected]@@@      [email protected]@@@@#                //
//            .*@@@@@@@@@@@@@@*      %@@@@@@@@@@= [email protected]@@@@@@@@@*         [email protected]@@@@+.:@@@@-  [email protected]@@@@@@@@@@+   [email protected]@@.    @@@@:         @@@@        :#@@@@%%+             //
//            .#@@@@#.   [email protected]@@@@      @@@@@*=*#*-  :@@@@@@@@@@@+      :%@@@@@@@@@@@@@-  [email protected]@@@@@@@@@@@+  [email protected]@@*    %@@@+         @@@#    :.    .#@@@@@@:           //
//            :@@@@@#    [email protected]@@@@      %@@@@+       [email protected]@@@@@*[email protected]@@@#=:   #@@@@@%##%@@@@@:  [email protected]@@@@#@@@@@@@: [email protected]@@@=   [email protected]@@%        [email protected]@%.   %@@*    :%@@@@@#           //
//            =*@@@@@.   *@@@@#      %@@@@*        %@@@@@=  :*@@*-  [email protected]@@@@%    @@@@@+  [email protected]@@@@ .*@@@@@%[email protected]@@@@    #@@%-      -%@*    #@@@@.    #@@@@@%           //
//            [email protected]@@@@@-.-%@@@@*       #@@@@@%#@*:   %@@@@@-         [email protected]@@@@@*    *@@@@*  %@@@@%   [email protected]@@@@%#@@@@*    .%@@@@%%%%@@@-     #@@@@@*+=#@@@@@@*           //
//            :@@@@@@@@@@@@#.        %@@@@@@@@@%   %@@@@@+         %@@@@@@:    [email protected]@@@%  @@@@@%   .%@@@@@ =%#=      .#@@@@@@@@@#      [email protected]@@@@@@@@@@@@@@=           //
//            [email protected]@@@@%====:           #@@@@@@@**=  .#@@@@@#        :@@@@@@#      %@@@% *@@%:.      [email protected]@@#             -#@@@@@@@-       *@@@@@@@@@@@@%%:           //
//            [email protected]@@@@                 %@@@@@@@-     [email protected]@@%+.       .%@@@@@@=       @@@-  +%:        [email protected]@@:               %@@.::.        :@@@*+#@@@@::#@.           //
//             %@@@-                 #@@*-##-:     [email protected]@@#          [email protected]@@@@@=       %@%              [email protected]@+                [email protected]%.            @@-   [email protected]@%  :#.           //
//             [email protected]@+                  @@@=          [email protected]@@%           %@%=--.      [email protected]@#              :@@:                 .=             %@     @@#   .            //
//             [email protected]@+                  #@@=          -%@@@-          %@-          [email protected]@%              [email protected]@:                                .-     @@#                //
//             [email protected]@*                  *@%:           [email protected]@@-          -#:           %@*               %@.                                      :@@*                //
//             *@@=                  #@.             [email protected]                       [email protected]@%               ..                                       [email protected]@=                //
//             *@@:                  #*               [email protected]=                        @@=                                                        #@@.                //
//             *@@                                     %#                       [email protected]@+                                                        :@@:                //
//             [email protected]@                                    [email protected]*                       [email protected]@:                                                        [email protected]@-                //
//             *@*                                     %+                        %#                                                         [email protected]@*                //
//             *@-                                     *-                                                                                   [email protected]@-                //
//             *@-                                     -                                                                                    :@@.                //
//             :*                                      :                                                                                     %=                 //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BR is ERC721Creator {
    constructor() ERC721Creator("BekaRios", "BR") {}
}