// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gangland
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                      //
//                                                                                                                      //
//                                                      .:-==+++++=-:.                                                  //
//                                                 :=*%@@@@@@@@@@@@@@@@#+-.                                             //
//                                             -+%@@@@#+=:.       .:-+#%@@@%*-                                          //
//                                          -*@@@@*=:                   .-+%@@@#-                                       //
//                                       [email protected]@@%+==+**+-             .=*%%#*=:-#@@@+                                     //
//                                     .*@@@*-+%%@@@@@@@*          *@%@@@@@@@%=.*@@@=                                   //
//                                    [email protected]@@*[email protected]%#@@@@@@@@@%       .%@#@@@@@@@@@@%..%@@#                                  //
//                                  .#@@#. #@*#@@@@@@@@@@@#     [email protected]@*@@@@@@@@@@@@@. *@@%.                                //
//                ......:::-==+*** [email protected]@@-  #@*%@@**@@@@@@@@@:    #@*%@#  [email protected]@@@@@@@%  *@@% *%**+=--::..                   //
//               [email protected]@@@@@@@@@@@@@@@[email protected]@%.  [email protected]#*@@-  %@@@@@@@@*   :@%*@@#:.#@@@@@@@@@=  #@@#@@@@@@@@@@@@@@@%*              //
//               #@@@@%%##**++#@@@@@%.  [email protected]%[email protected]@@%+#@@@@@@@@@%   #@#%@@[email protected]@@@@@@@@@@#  [email protected]@@@@@@%%@@@@@@@@@@@              //
//               [email protected]@@* -+**#- [email protected]@@@@.   [email protected]%*@@@.:@@@@@@@@@@@   @@[email protected]@@:.%@@@@@@@@@@@   [email protected]@@@@#  -----..%@@@.             //
//               [email protected]@@* %%..    @@@@-    [email protected]#*@@@%%@@@@@@@@@@@   @@*@@@@@@@@@@@@@@@@@    @@@@@:  [email protected]# @@@@.             //
//               [email protected]@@# #%      #@@%     [email protected]#[email protected]@@@@@@@@@@@@@@@   @@[email protected]@@@@@@@@@@@@@@@@    #@@@*       @# @@@@:             //
//               [email protected]@@# #@      [email protected]@+     [email protected]%*@@@@@@@@@@@@@@@@   %@[email protected]@@@@@@@@@@@@@@@%    [email protected]@@.      [email protected]* @@@@:             //
//               :@@@% .:       #%.     [email protected]@*#@@@@@@@@@@@@@@#   [email protected]#%@@@@@@@@@@@@@@@*    [email protected]@=       .+::@@@@              //
//                @@@@                  :@@%*@@@@@@@@@@@@@@-    @@#@@@@@@@@@@@@@@@+                  [email protected]@@%              //
//                %@@@.                  @@@#[email protected]@@@@@@@@@@@*     :@%#@@@@@@@@@@@@@@-                  %@@@#              //
//                *@@@@@@@@@@@@-         #@[email protected]%*%@@@@@@@@@@.      *@%#@@@@@@@@@@@%@:         .::::[email protected]@@@+              //
//                [email protected]@@@@@@@@@@#:         [email protected]:.#@#*#%%@@@@@*       [email protected]@@#%@@@@@@@%:#@        :@@@@@@@@@@@@@@.              //
//                 .*@@@+-.              [email protected]*  .=*####*-%@.        [email protected]##@%%%@@%=  %%         +#%%%@@@@@@#=:               //
//                .%@@+                   %@-         #@+          %@- .:::    :@*               .=#@@@#                //
//                @@@+.:. =#.       ##:   [email protected]@-      :%@%     -:    :@@=        %@+                  :@@@#               //
//               [email protected]@@..=%@@#=  :.   %@*   :@#%*.  :*%#@:    #@@+    [email protected]@*.     #@@- -=.       .#%--** :@@@:              //
//               *@@@. =*: .:-#@@#  [email protected]@    #@ -+**=:[email protected]    #@@@@+    #%=#*=-+%*#@  @@=   -+. =###@*   @@@-              //
//               [email protected]@@%=::-=*@@@@#    @@#   [email protected]+     [email protected]=    [email protected]@@@@@-    #*  ::: [email protected]* [email protected]@.  [email protected]@@*:   .=. *@@@               //
//                [email protected]@@@@@@@%*[email protected]%    #@@%:  [email protected]+   [email protected]     @@@%%@@%     #*     #@. *@#    [email protected]@@@@#+==+%@@@.               //
//                  :----:    [email protected]@    [email protected]@@@*: .+#*#+.     [email protected]@# .#@@.     +%-.:#%. [email protected]@-    @@::=#@@@@@@%+                 //
//                            %@@    [email protected]@@#[email protected]#-            ..    ::        -++- .#@@@.   [email protected]@      :::.                   //
//                           :@@@    [email protected]@@#  =#@+:                            .*@%@@@    #@@                             //
//                           *@@@    [email protected]@@*    *@@%+-                       -#@*[email protected]@@    #@@.                            //
//                           @@@*    [email protected]@@=    @@@%-*%%*=-.            :-+%@*-   :@@@    *@@+                            //
//                          [email protected]@@-    %@@@.   [email protected]@@=    :@@@#%%#####%%%#**@@@:     %@@-   :@@@.                           //
//                          %@@@    [email protected]@@*    %@@@.     @@@     @@@:     %@@%     [email protected]@#    #@@*                           //
//                         :@@@=    %@@@.   [email protected]@@#     [email protected]@%     %@@+     :@@@+     %@@:   [email protected]@@-                          //
//                         *@@@    [email protected]@@-    %@@@-     [email protected]@#     [email protected]@%      *@@@:    [email protected]@#    [email protected]@@.                         //
//                        :@@@-   :@@@+    [email protected]@@%      [email protected]@*     [email protected]@@      [email protected]@@%     *@@+    #@@%.                        //
//                       .%@@#   [email protected]@@*    [email protected]@@@=      #@@+     [email protected]@@-      [email protected]@@*     %@@-    #@@@:                       //
//                       %@@%   .%@@+     #@@@@       %@@-      @@@*       @@@@=     %@@-    #@@@-                      //
//                      #@@@.  .%@@-     [email protected]@@@+       @@@:      #@@%       [email protected]@@@:     #@@=    *@@@*                     //
//                     #@@@:  :@@@:      @@@@@    ..:[email protected]@@=------#@@@:.      %@@@%      *@@#.   [email protected]@@%.                   //
//                   .%@@@:  [email protected]@%.    .:*@@@@@%@@@@@@@%%%%###%%%%%%@@@@@@@%%@@@@@#-:.   [email protected]@@=   :@@@@=                  //
//                  [email protected]@@%. -%@@@*#%@@@@@%#*+=----------=========-----:::------==+*#%@@%#*#@@@%=  .#@@@#.                //
//               [email protected]@@@+  *%##*+==----==+*#%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%##*+=-----=+#%@@*. [email protected]@@@=               //
//              [email protected]@@@@=::-==+*#%@@@@@@@@@@%#*++=--::..............:::::---==++**#%@@@@@@@@%#*+===:...#@@@#              //
//             :@@@@@@@@@@@@@@%##*+=-:.                                              .:--=+*#%@@@@@@@@@@@@-             //
//              :==---:::..                                                                      .::--==+=              //
//                 .                                    .                                                               //
//              *@%*#%*      [email protected]@#      [email protected]@#  %@.    :#@#*#%=    [email protected]+         *@@*      [email protected]@*  %@     %@%#%%+              //
//             %@= ..::     [email protected]#*@=     [email protected]#@%:%@.   :@@. ..::    [email protected]+        [email protected]**@=     [email protected]#@%.%@     %@:  [email protected]#             //
//             %@- +#@%    [email protected]@*[email protected]@:    [email protected]=.%@@@.   :@@..+%@+    [email protected]+       [email protected]@[email protected]@:    [email protected]=.%@@@     %@:  [email protected]#             //
//             .#@#*#@#    #@=::[email protected]%    [email protected]=  *@@.    -%@#+%@+    [email protected]%###-   %@-::[email protected]%    [email protected]=  *@@     %@#*%@+              //
//                ...                                  ...                                                              //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GANG is ERC721Creator {
    constructor() ERC721Creator("Gangland", "GANG") {}
}