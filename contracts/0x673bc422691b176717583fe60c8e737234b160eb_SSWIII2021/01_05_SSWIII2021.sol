// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SSWIII 2021 EVERYDAYS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                               -##*+=.                                                      //
//                                            .+#=.   :=**+-.                                                 //
//                                          =#*:           :=+**-.                                            //
//                                       :*#-               .+%+-=+*+-:                                       //
//                                    .+%+:               =#*-       .-+++=:                                  //
//                                  =#*+#@#+-.         :*#=.              .:+++=:                             //
//                               -*#-     :=+#%#+-. .+#+.                    :*@@-                            //
//                            .*%+:            :-*@@@@=                    -%@@@@*                            //
//                          -#*:               .*%+::-+#%*+-.           :*@@@@@@@@        :--.                //
//                       :*#=               .=%*:        :=*%%#=-.    =#@@@@@@@@@@=:-=*#**+-=##+:             //
//                    .+%@-               :*#=.              .:=*%%#*@@@@@@@@@@@@#*+-:.        :=#*=:         //
//                  =##-=*@@*=.        .+%*.                     =%@@@@@@@%#+--+%%+-.              :+#*-.     //
//               :*#=      .-+#%#=:  -#*-                     :[email protected]@@%*+=-.         :+#%*=:         [email protected]%@#    //
//            .+%*:             [email protected]@@@+                .:=*##*+*@%-:                  .=*@#+-=+###+=:.  *#    //
//         .=##-               .+%*-:=+%%+=:    .-=*#**+=-.      :=*%*=:            .-=+#%@@#-.         %+    //
//       :*%+.               -#%=.       -+%@#%@@=:.                 .-+%#+-..:=+###*+-.  [email protected]          [email protected]    //
//    :=%*:               :+%+.             %#:=#%#+:                 .:=#@@@*+-:         %@.          [email protected]    //
//    #@@@*=.           =##-                @=    .=#@%*=.     .:-+#%%*+-:.%%             @%           *%     //
//    [email protected]+ -+%%*=.    :*%+.                 :@-        .=*%%#*%#*+=:.       @*            :@*           %*     //
//     :@:    -*%@**%*:                    [email protected]            [email protected]+             :@+            [email protected]=          :@-     //
//      +%        -%@@*=.                 =%@.            *@=             [email protected]            [email protected]:          [email protected]     //
//       #*        [email protected]@-+#@*=.          :*@@@@             #@:             [email protected]            #@.          ##      //
//       [email protected]:        [email protected]=   :+#%*-.   .=%@@@@@#             @@.             #@             @%      .-=+#@+      //
//        -%         %%       :+%@*#@@@@@@@@+             @@              @@            [email protected]*.-+*%@%#*[email protected]      //
//         ##        :@=          [email protected]@@@@@@@@=            :@@             [email protected]*        .:=*%@@%*+-:     [email protected]       //
//         [email protected]%+-.     *@.          [email protected]@@@@@@@-            [email protected]#             :@=  .-=*%@@%*[email protected]@.          **       //
//          [email protected]**%%*=. [email protected]#           @@@@@@@@#+-.         [email protected]+            .*@%%@@#+=:.    @%           #=       //
//           *#   -+#%*@@=          [email protected]@@@@@@+*%@%#+-.    *@+     .:=+#%@@@@+:.          @*           @-       //
//            %=      :[email protected]@#=:        #@@@@@%    :=*%@@%+=%@=-=*%@@@#+-:  @@            [email protected]+          [email protected]        //
//            :@:       :@#=*%#+-.   :@@@@@*         :=*%@@@%*+-.        @#            [email protected]          +#        //
//             *@        *@.  .=*%@*-:#@@@@+            [email protected]@.            :@+            #@.          #+        //
//              %*        @+      .-+%@@@@@=            :@@             [email protected]            @@        [email protected]        //
//              [email protected]=       [email protected]:          [email protected]@@-            [email protected]%             [email protected]:           :@#   :=#@@%*#@.        //
//               [email protected]*=:     @%           @@@             [email protected]#             *@            [email protected]%#@@%*=:   +%         //
//                #@=*%#+: [email protected]=          [email protected]%             #@+             %%       :=*#@@@*-.        #+         //
//                [email protected]=  .-+#%@@.          %%             @@=             @# .:+*#@@#+-:@@           @-         //
//                 [email protected]:      [email protected]@#+-       #%:            @@:            [email protected]@@@@*=:.     @#          :@.         //
//                  *%       [email protected]=-+#%+-.  @@@@#*=:      [email protected]@.      :-+#@@@@*-.         :@+          +#          //
//                   %+       %#    -+#%#@: .-+%@@%+-. :@@  :=*%@@%*=: [email protected]            [email protected]          %+          //
//                   :@+:     [email protected]=       [email protected]:      :-+#@@@@@@@@#+=:      %@            *@.        :[email protected]:          //
//                     :+%*=.  %%       [email protected]            .#@%-.           @#            %%     :+##+-            //
//                        .=*%**@*      +%             *@+            [email protected]*            @* :=#*+-                //
//                            .=#@*-    ##             #@=            [email protected]+           [email protected]@%+:                    //
//                                :+##[email protected]+             @@:            [email protected]       -+#*=:                        //
//                                    -*@-             @@.            *@.   -+#*=:                            //
//                                     [email protected]*-           :@@             @@-+##=.                                //
//                                      -*@@#=.       [email protected]%           -*@#=.                                    //
//                                         :+%@%+:    [email protected]#       -+#*=.                                        //
//                                            .-#@@#=.*@*   -*##=.                                            //
//                                                :[email protected]@@@@*##=.                                                //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SSWIII2021 is ERC721Creator {
    constructor() ERC721Creator("SSWIII 2021 EVERYDAYS", "SSWIII2021") {}
}