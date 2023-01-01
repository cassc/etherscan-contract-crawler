// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Arcana Girl Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                         :                                                                                           //
//                                     .+#@:                                                                                           //
//                                   .+%@@+                                                                                            //
//                                  =*:#@@:                                                                                            //
//                                -*-  @@%                                                                                             //
//                              :*=   [email protected]@+                                                                                             //
//                            .++     [email protected]@:                                                                                             //
//                           =*.      #@@                                                                                              //
//                         :*:       [email protected]@*                                                                                              //
//                       .*=         [email protected]@=                                                                                              //
//                      =*.          [email protected]@:                                           .+*.                                =#:            //
//                    :%*            %@%           +:   :++=     .-**+.         :===%@+=:      ==    =#%           .-==#@*=:           //
//                  .*++++======++##*@@*          *@+.=##@@+   .++==%@*       =#=. #@-        [email protected]#  [email protected]@=         -#+. [email protected]#-.            //
//                 =*:             [email protected]@@=         [email protected]#==.  .=   =+.   :@-     =%+   [email protected]=        .%%[email protected]=        -%*.  [email protected]@@@*            //
//               :#=                #@@.        [email protected]@+.       .*+     ..    :%%:   [email protected]*         #@-+: [email protected]=       .*@=  :#@%[email protected]@=     ..     //
//             .+*.                 %@%        [email protected]@=        .##           [email protected]%.   [email protected]%         [email protected]%-  :@+       :%@- .*@@@:[email protected]%     :+      //
//            -%=                  [email protected]@*       :@@-         *@:         .*@%.   [email protected]@:       .*@#.  .%#       [email protected]@- [email protected]@@@- %@:    =-       //
//          .##.                   [email protected]@+      .%@-         [email protected]%         -%@@:   +%@=       -*%#   .%%.      [email protected]@=.#@@%@* [email protected]   .+.        //
//         [email protected]+                     [email protected]@+     .%@=          #@#       :[email protected]@+  :[email protected]#      [email protected]%.   *@-     [email protected]@#.#@#[email protected]@..%+   ==          //
//       :%@-                      %@@%-.:: #@+           #@@.   .-+- [email protected]@.:+- #@=    .==:@%.   [email protected]%    :[email protected]@=%@* [email protected]* #+  -=.           //
//      [email protected]%:                       #@%*+-. .%+            :#@@*++=.   [email protected]@*-   %@-  -==  .%:    [email protected]@--==-  [email protected]@@@*  *@*#+:==.             //
//     [email protected]#.                                                  .         .      :*#*+:            ---:      .%@*   .*@#+-                //
//     +%.                                            :-==+++++=-:                                        #@*    .#-                   //
//     -=                                        .-+#*=:.   .:=*@@@#-                                    *@*    :#:                    //
//     ..                                      -#@*-            [email protected]@@:                                  [email protected]#    =*                      //
//                                           =%@*:                [email protected]#         :-                       [email protected]#.  .*-                       //
//                                         -%@%-                   @:        [email protected]@:                     [email protected]%.  =+.                        //
//                                       .*@@#.                   .+         *#-                     :@%. :+:                          //
//                                      :%@@*                                                       :@%.:+-                            //
//                                     :@@@+                                                       .%@++:                              //
//                                    :@@@+                                                       .%@+.                                //
//                                   .%@@*                        .:                             .#@-                                  //
//                                   #@@#              .+++===*#%@+:     :++  ..    :%=  :+%%#   #@=                                   //
//                                  [email protected]@@.                     #@@=      [email protected]%+*%@@@. .%@--++=#@:  *@+                                    //
//                                  %@@+                     [email protected]@*      [email protected]@%*++*@=  #@*=.    .  [email protected]#                                     //
//                                 [email protected]@%                     [email protected]@%      :@@-        #@%-        [email protected]%.          +.                         //
//                                 [email protected]@+                    [email protected]@@:     [email protected]@=        *@%.        :@@-         :+.                          //
//                                 *@@-                  :#@@@-    .*@@#       .#@%.         %@*         ==                            //
//                                 [email protected]@-                .+#[email protected]@+    -*[email protected]@:      =#@%.         [email protected]@.       -+.                             //
//                                  #@*              :**-.%@#    += @@#    [email protected]%:          %@%      -+:                               //
//                                   [email protected]*.         :+*=.  #@%.  .#-  %@%-:-+=..%@:           *@@-..-=+:                                 //
//                                    .=*++======+-.    *@@:  .#-   .-==-.    +-             =***=:                                    //
//                                   .....             [email protected]@-  :%-                                                                       //
//                %%#**++*%%%%++***###%@@+            [email protected]@=  :%-                                                                        //
//                .      #@@#.          *            [email protected]@=  [email protected]                                                                         //
//                      [email protected]@#.                       [email protected]@+  [email protected]                                                                          //
//                     [email protected]@#.                       [email protected]@+  [email protected]       :##           :++-       +#-                                        //
//                    .%@%.                       *@@-  [email protected]=        @@*         .%@-        [email protected]%:                                        //
//                    #@%.                      .#@%:  :@=         -:         .%@-         .-.                                         //
//                   *@@:                      [email protected]@+   :%+                    .%@-                                                      //
//                  [email protected]@-                     -%@*:   .%*                     #@=                                                       //
//               .=#@@#--------==+*#:     .=%%+.    .%#                     *@+                         .*%-                           //
//               [email protected]@*-----------===+====++=.    .-=#%.         ..         *@*           :            .-*@%        -:    :*#           //
//               .%@#                         .===:*@:        .#@:    .###@@#*+++====. [email protected]*         .+#- *@*       :@%  :[email protected]@+           //
//              .%@%.                       .**.  [email protected]=        .%@-        [email protected]#          [email protected]#         [email protected]+   [email protected]*       %%::+:[email protected]+            //
//              #@@:                       [email protected]=   [email protected]*        .%@=        [email protected]%.         [email protected]%.       .%@=    *@%.     *@-+- :@*             //
//             *@@=                      .#@-   [email protected]%         #@*        :@@-         [email protected]@:       :%@=    -#:##-:-=#@%+  .%#        =-    //
//            [email protected]@*                      .%@-   [email protected]@:        *@#        [email protected]@*         :@@-       .%@+    .#.  .::..%%:  .%%.       +-     //
//           [email protected]@@.                     .%@=   [email protected]+        [email protected]@:      .+*@@:         %@*       =%@%    .#.      .#%.   #@:      :+.      //
//          [email protected]@@#                  .-*:#@#  :*.%%        [email protected]@*     [email protected]@%         [email protected]@:     [email protected]@-   :#.      :%%:   [email protected]=      ==        //
//          [email protected]@@%              :=+#@#[email protected]@=.+= [email protected]=        *@@+   :+=  :@@@.   .=+: #@@   .=+: *@@.  =+       .%@:   :@@    .=+.         //
//          .*@@@%+-:::--=+**##*+=-.  [email protected]@@*.  *@.      .*.*%@*++-     #@@%*++=.   -#@%++=.   [email protected]@*==:        :@-    [email protected]%:.-==.           //
//             .:------:::.            ::     #%      =+               .:..                   .-:            .     .=++-.              //
//                                            [email protected]  .=+:                                                                                //
//                                             :=+=-.                                                                                  //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AGE is ERC1155Creator {
    constructor() ERC1155Creator("Arcana Girl Edition", "AGE") {}
}