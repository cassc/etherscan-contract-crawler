// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Wes Henry
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                  -=                                                                                  //
//                                  +%                                             .#=                                  //
//                              .++*%@@%@@@@@@@@@@@@@%%%%%%%%######****+++++******##@@#**+                              //
//                                  #@*...:::--=--====+***#%%%%@@@@@@@@@@@%%%%%%%##%@@@@@=                              //
//                                  #@%                                            [email protected]@*::                               //
//                                  *@@.        -+                                 [email protected]@*                                 //
//                                  *@@:        *@-                 .:.             @@%                                 //
//                                  #@@:        %@*        :-       *@%             @@@.                                //
//                                  #@@-        @@%        *@+      *@@.            @@@:                                //
//                                  #@%-       [email protected]@@.       #@=      #@@=            %@@-                                //
//                                  %@%:       :@@@-       %@+      %@@-            %@@=                                //
//                                  @@@:       :@@@:       %@+      %@@+            #@@+                                //
//                                  @@@:       [email protected]@@:      .%@#      %@@+            %@@+                                //
//                                 [email protected]@%        [email protected]@@:      :@@%      #@@%            #@@+                                //
//                                 [email protected]@%        [email protected]@@:      [email protected]@@      *@@%            #@@+                                //
//                                 :@@#        [email protected]@@-      [email protected]@%      [email protected]@@.           %@@+                                //
//                                 [email protected]@*        [email protected]@@-      [email protected]@@.     [email protected]@@:           #@@+                                //
//                                 [email protected]@*        [email protected]@@:      [email protected]@@.     [email protected]@@.           #@@=                                //
//                                 [email protected]@+        [email protected]@@:      [email protected]@@.     [email protected]@%:           %@@=                                //
//                                 *@@+        [email protected]@@:      [email protected]@@.     :@@@-           %@@-                                //
//                                 #@@=        [email protected]@@:      [email protected]@@.     :@@@+           %@%:                                //
//                                 #@@-        [email protected]@@:      :@@@.     [email protected]@@=           #@@:                                //
//                                 %@@=        [email protected]@@:      :%@@.     .%@@+           %@@:                                //
//                                 @@@-        [email protected]@@:      [email protected]@@.      %@@*           %@%.                                //
//                                 @@@:        [email protected]@%:      .%@@       %@@*           %@%.                                //
//                                [email protected]@@-        [email protected]@@:      [email protected]@@       #@@#           %@@.                                //
//                                :@@@-        [email protected]@@:       %@%       *@@%           %@%                                 //
//                                [email protected]@@:        [email protected]@@:       %@%       *@@@.          %@%                                 //
//                                [email protected]@@-        [email protected]@@:       #@@       [email protected]@@.          %@%                                 //
//                                [email protected]@@-        :@@@:       #@@       [email protected]@%.          @@#                                 //
//                                *@@@:        [email protected]@@-       #@%       [email protected]@@:          @@#                                 //
//                                #@@@-         @@@-       *@@.      [email protected]@@:          @@+                                 //
//                                @@@@-         @@@-       *@@:      :@@@-          @@+                                 //
//                               .%@@@-         %@@-       *@@:      [email protected]@@-          @@=                                 //
//                               :%@@%-         %@@-       [email protected]@:      [email protected]@@-          @@-                                 //
//                               :@@@@:         #@@-       [email protected]@=      [email protected]@@-         [email protected]@-                                 //
//                               [email protected]@@%-         %@@=       [email protected]@+      [email protected]@@-         [email protected]%:                                 //
//                               [email protected]@@@-         #@@-       [email protected]@*      [email protected]@@-         [email protected]@:                                 //
//                               [email protected]@%@-         #@@-       [email protected]@*       @@@-         [email protected]@.                                 //
//                               [email protected]@@@-         #@@:       [email protected]@*       @@@-         :@@                                  //
//                               [email protected]@@@=         #@@:       :@@#       @@@-         [email protected]%                                  //
//                               [email protected]@@@=         #@@.       [email protected]@#       %@@-         [email protected]%                                  //
//                               [email protected]@@@=         *@@.       [email protected]@*       %@@:         [email protected]#                                  //
//                               [email protected]@@@+         #@@.       :@@*       %@@:         [email protected]*                                  //
//                               [email protected]@@@=         *@@.       [email protected]@+       #@@.         #@*                                  //
//                               =%@@@=         *@@.       [email protected]@+       *@@.         %@+                                  //
//                               [email protected]@@@+         [email protected]@.       [email protected]@=       *@%.         %@+                                  //
//                               [email protected]@@@*         [email protected]@.       [email protected]@-       [email protected]%          %@-                                  //
//                               [email protected]@@@*         [email protected]@        [email protected]@:       [email protected]%          %@=                                  //
//                               [email protected]@@@#         [email protected]@        [email protected]@:       [email protected]%         [email protected]@-                                  //
//                               :@@@@#         [email protected]%        [email protected]@        [email protected]#         [email protected]@-                                  //
//                               :@@%@*         *@%        :@%        [email protected]=         [email protected]@-                                  //
//                               [email protected]@@@#         =%=         :-                     @@-                                  //
//                                %@@@%                                           [email protected]@:                                  //
//                                #@@@%.                                           @@:                                  //
//                                #@@@%::::--===+++++******########%%%%%%@@@@@@@@@%@@:                                  //
//                                #@@@@@@@@@@@@%%%%%%%%%####*#*#*******++**[email protected]@.                                  //
//                                *@@@@:                                           %@.                                  //
//                                *@@@@:                                           @@                                   //
//                                [email protected]%@@-                                           @@                                   //
//                                [email protected]@@@-                               +*=         @@                                   //
//                                *@@@@-              :*:  ..         #@**%.       @@.                                  //
//                                *@@@@=              [email protected]% [email protected]%***.    *@%  #=       @@.                                  //
//                                #@%@@-              [email protected]@:[email protected]%       [email protected]@-  :#       @@:                                  //
//                                #@%@@=              [email protected]@=:@@       *@#    +-      @@:                                  //
//                                #@%@%-              [email protected]@+:@@.      %@*            @@:                                  //
//                                #@#%@=              [email protected]@*[email protected]@:      #@+            @@-                                  //
//                                %@#%@+   #          *@@*[email protected]@=      :@%.           @@=                                  //
//                                %@#@@+   #:         *@@* @@*       :#%:          %@=                                  //
//                                %@#@@=   %+         #@@+ %@*         :++++-      @@=                                  //
//                                #@#@@+   %#   -+-   #@@* %@*             .#@*:  [email protected]@*                                  //
//                                #%*@@+   %%  [email protected]@@+ .%@@= #@%#%*:           %@%. [email protected]@*                                  //
//                                *@*%%+   #@: [email protected]@@@[email protected]@@- *@=...            %@@+ :@@%                                  //
//                                #@*%@=   #@[email protected]@@+%[email protected]@@- *@-              [email protected]@@: :%@#                                  //
//                                *@*@@+   *@+=%@# #%:@@@= *@:      :*+.   [email protected]@@+  :@@%                                  //
//                                *@*@@=   [email protected]%%@@- [email protected][email protected]@@= *@-      :@@*  [email protected]@@=   :%@%                                  //
//                                *@#%@=   *@@@@%  [email protected]#%@%= #@-       %@@[email protected]@@=    :%@%.                                 //
//                                [email protected]#@@-   *@@@@-   *@%@@= #@=       [email protected]@#@@@+     :#@%.                                 //
//                                [email protected]%%@:   *@@@#    [email protected]@@@= #@=        %@@@@=      -%%%:                                 //
//                                *@@@@:   *@@@:     %@%@[email protected]@+-==:    [email protected]@@-       -%#@-                                 //
//                                [email protected]#@%.   :@@*      [email protected]@@= :::..       =+-        -##@-                                 //
//                                *@@@%    .%#        #@@-                  .::-=+*@%@=                                 //
//                               .%@@@@*++++*++***+*++#@@#****######%%%%@@@@@@%%%##@#@=                                 //
//                               .%@@@@#%###############*##**+*+++=--:::..       .:%*@=                                 //
//                                [email protected]@@#                                    -   .#+.%*@=                                 //
//                                [email protected]@@#                 .*:       .++--:   .%+-%+ .%*@=                                 //
//                                :@@@+                 [email protected]@. *%:   =%  .#+   *@*   %#%+                                 //
//                                [email protected]@@+  .   -*  +=-:.  :@@+ #@%   :@. =%=   [email protected]#   #%%=                                 //
//                                 @@@=  =+  [email protected] %#:... [email protected]@%.%@%.  :@%%=.    [email protected]@   +%@+                                 //
//                                 %@@-  -*  *@: @+     [email protected]@@[email protected]@@-  :%@@.      %@.  -%%+                                 //
//                                 %@@-  =# [email protected]@.:@-     *%%@%@@@=  :%*@%      %@-  [email protected]@*                                 //
//                                 %@@-  +# [email protected]% =%..:.  #%[email protected]@@@@+  .#.%@=     *@=   %@*                                 //
//                                 #@@:  *%=#@# #@#=.   %#.%@@@@*  .% [email protected]@:    *@=   %%#                                 //
//                                 #@@.  %# #@[email protected]     .%= *@@@@#   %  %@#    [email protected]*   #@#                                 //
//                                 *@@.  @= %@[email protected]     :%: [email protected]@@@#   #  [email protected]@-   [email protected]=   *@#                                 //
//                                 [email protected]@: [email protected] %@=%@=*##* -#   %@@@@   *.  %@%.  [email protected]+   *@%                                 //
//                                 [email protected]@.  :  :=:#*:.    ..   [email protected]@@@:  =:  :%@+  .#-   [email protected]@.                                //
//                                 [email protected]@                      .%@@@:  :.   .:.        [email protected]@.                                //
//                                 [email protected]@                       [email protected]@@-                  :@@-                                //
//                                 :@@                        :%%:                   %@=                                //
//                                 .%@.                                              #@=                                //
//                              .---%@+=++++++*+*+******+*+++++++=+==================%@+                                //
//                              :**####*+++====---:::::::.:.:..:.............::::::..=%-                                //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract WES is ERC721Creator {
    constructor() ERC721Creator("Wes Henry", "WES") {}
}